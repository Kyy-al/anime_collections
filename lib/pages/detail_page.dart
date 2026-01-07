import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../main.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> anime;

  const DetailPage({Key? key, required this.anime}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  bool _isFavorite = false;
  bool _isLoading = false;
  YoutubePlayerController? _youtubeController;
  List<Map<String, dynamic>> _episodes = [];
  bool _isLoadingEpisodes = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _initializeVideoPlayer();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() => _isLoadingEpisodes = true);

    try {
      final malId = widget.anime['mal_id'];
      if (malId != null) {
        final episodes = await _apiService.getAnimeEpisodes(malId);
        setState(() => _episodes = episodes);
      }
    } catch (e) {
      print('Error loading episodes: $e');
    } finally {
      setState(() => _isLoadingEpisodes = false);
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? 1;

    // Check if anime is from local database (has 'id') or from Jikan (has 'mal_id')
    final animeId = widget.anime['id'];
    if (animeId != null) {
      // Anime from local database
      final isFav = await _dbService.isFavorite(animeId, userId);
      setState(() => _isFavorite = isFav);
    } else {
      // Anime from Jikan - check if it exists in local database by mal_id
      final localAnime = await _dbService.getAnimeByMalId(
        widget.anime['mal_id'],
      );
      if (localAnime != null) {
        final isFav = await _dbService.isFavorite(localAnime['id'], userId);
        setState(() => _isFavorite = isFav);
      } else {
        setState(() => _isFavorite = false);
      }
    }
  }

  void _initializeVideoPlayer() {
    final trailerUrl = widget.anime['trailer_url'] ?? '';

    if (trailerUrl.contains('youtube.com') || trailerUrl.contains('youtu.be')) {
      final videoId = YoutubePlayer.convertUrlToId(trailerUrl);

      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: true,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? 1;
    setState(() => _isLoading = true);

    try {
      int animeIdToUse;
      final animeId = widget.anime['id'];

      if (animeId != null) {
        // Anime from local database
        animeIdToUse = animeId;
      } else {
        // Anime from Jikan - check if it exists in local database
        var localAnime = await _dbService.getAnimeByMalId(
          widget.anime['mal_id'],
        );
        if (localAnime == null) {
          // Save anime to local database first
          final animeData = {
            'title': widget.anime['title'] ?? '',
            'description': widget.anime['description'] ?? '',
            'genre': widget.anime['genre'] ?? '',
            'rating': widget.anime['rating'] ?? 0.0,
            'image_url': widget.anime['image_url'] ?? '',
            'trailer_url': widget.anime['trailer_url'] ?? '',
            'release_date': widget.anime['release_date'] ?? '',
            'mal_id': widget.anime['mal_id'],
            'created_at': DateTime.now().toIso8601String(),
          };
          animeIdToUse = await _dbService.insertAnime(animeData);
        } else {
          animeIdToUse = localAnime['id'];
        }
      }

      if (_isFavorite) {
        await _dbService.removeFromFavorites(animeIdToUse);
        // Also call API to remove from server
        // await _apiService.removeFavorite(animeIdToUse, authProvider.token!);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dihapus dari favorit')));
        }
      } else {
        await _dbService.addToFavorites(animeIdToUse, userId);
        // Also call API to add to server
        // await _apiService.addFavorite(animeIdToUse, authProvider.token!);

        await _notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '⭐ Ditambahkan ke Favorit',
          body: '${widget.anime['title']} telah ditambahkan ke favorit',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ditambahkan ke favorit')),
          );
        }
      }

      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editAnime() async {
    // Show edit dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditAnimeDialog(anime: widget.anime),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // If anime has a server_id, update remote server; skip otherwise.
        final serverId = widget.anime['server_id'];
        if (serverId != null) {
          await _apiService.updateAnime(serverId, result, authProvider.token!);
        }

        // Update local database (local id must exist for editable items)
        final localId = widget.anime['id'];
        if (localId != null) {
          await _dbService.updateAnime(localId, result);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anime berhasil diupdate')),
        );

        // Navigate back to refresh
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAnime() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Anime'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${widget.anime['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // If anime has a server_id, delete on server first.
        final serverId = widget.anime['server_id'];
        if (serverId != null) {
          await _apiService.deleteAnime(serverId, authProvider.token!);
        }

        // Delete from local database (local id must exist for deletable items)
        final localId = widget.anime['id'];
        if (localId != null) {
          await _dbService.deleteAnime(localId);
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Anime berhasil dihapus')));

        // Navigate back
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.anime['image_url'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, size: 100),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Edit and Delete buttons only for local anime
              if (widget.anime['id'] != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _editAnime,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteAnime,
                ),
              ],
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _isLoading ? null : _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.anime['title'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.anime['rating'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Genre and Release Date
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(widget.anime['genre'] ?? ''),
                        backgroundColor: Colors.deepPurple.shade700,
                      ),
                      Chip(
                        label: Text(widget.anime['release_date'] ?? ''),
                        backgroundColor: Colors.deepPurple.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Sinopsis',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.anime['description'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trailer Section
                  if (_youtubeController != null) ...[
                    const Text(
                      'Trailer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.deepPurpleAccent,
                        bottomActions: [
                          CurrentPosition(),
                          ProgressBar(isExpanded: true),
                          RemainingDuration(),
                          FullScreenButton(),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final trailerUrl =
                                widget.anime['trailer_url'] ?? '';
                            if (trailerUrl.isNotEmpty) {
                              if (await canLaunchUrl(Uri.parse(trailerUrl))) {
                                await launchUrl(
                                  Uri.parse(trailerUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tidak dapat membuka trailer',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Trailer tidak tersedia'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Tonton Sekarang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Share functionality
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Bagikan'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Colors.deepPurpleAccent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Episodes Section
                  if (_isLoadingEpisodes)
                    const Center(child: CircularProgressIndicator())
                  else if (_episodes.isNotEmpty) ...[
                    const Text(
                      'Episodes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _episodes.length,
                      itemBuilder: (context, index) {
                        final episode = _episodes[index];
                        final isFiller = episode['filler'] == true;
                        final isRecap = episode['recap'] == true;

                        return Card(
                          color: const Color(0xFF0f3460),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.deepPurpleAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${episode['mal_id']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              episode['title'] ??
                                  'Episode ${episode['mal_id']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (episode['title_japanese'] != null)
                                  Text(
                                    episode['title_japanese'],
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                Row(
                                  children: [
                                    if (isFiller)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Filler',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    if (isRecap)
                                      Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Recap',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    if (episode['score'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${episode['score']}',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.play_circle_outline,
                                color: Colors.deepPurpleAccent,
                              ),
                              onPressed: () async {
                                final url = episode['url'];
                                if (url != null &&
                                    await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tidak dapat membuka episode',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            onTap: () async {
                              final url = episode['url'];
                              if (url != null &&
                                  await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ] else if (!_isLoadingEpisodes) ...[
                    const Text(
                      'Episodes tidak tersedia',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }
}

class EditAnimeDialog extends StatefulWidget {
  final Map<String, dynamic> anime;

  const EditAnimeDialog({Key? key, required this.anime}) : super(key: key);

  @override
  State<EditAnimeDialog> createState() => _EditAnimeDialogState();
}

class _EditAnimeDialogState extends State<EditAnimeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _genreController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _trailerUrlController;
  late final TextEditingController _ratingController;
  late final TextEditingController _releaseDateController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.anime['title'] ?? '');
    _descriptionController = TextEditingController(
      text: widget.anime['description'] ?? '',
    );
    _genreController = TextEditingController(text: widget.anime['genre'] ?? '');
    _imageUrlController = TextEditingController(
      text: widget.anime['image_url'] ?? '',
    );
    _trailerUrlController = TextEditingController(
      text: widget.anime['trailer_url'] ?? '',
    );
    _ratingController = TextEditingController(
      text: (widget.anime['rating'] ?? 0.0).toString(),
    );
    _releaseDateController = TextEditingController(
      text: widget.anime['release_date'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _genreController.dispose();
    _imageUrlController.dispose();
    _trailerUrlController.dispose();
    _ratingController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final result = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'genre': _genreController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'trailer_url': _trailerUrlController.text.trim(),
        'rating': double.tryParse(_ratingController.text) ?? 0.0,
        'release_date': _releaseDateController.text.trim(),
      };
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Anime'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Anime'),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Judul tidak boleh kosong'
                    : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Sinopsis'),
                maxLines: 3,
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Sinopsis tidak boleh kosong'
                    : null,
              ),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(labelText: 'Genre'),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Genre tidak boleh kosong'
                    : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL Gambar'),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'URL gambar tidak boleh kosong'
                    : null,
              ),
              TextFormField(
                controller: _trailerUrlController,
                decoration: const InputDecoration(labelText: 'URL Trailer'),
              ),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _releaseDateController,
                decoration: const InputDecoration(labelText: 'Tanggal Rilis'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
