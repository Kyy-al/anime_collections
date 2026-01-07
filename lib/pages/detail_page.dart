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
    final userId = authProvider.userId ?? 1; // Fallback to 1 if not set
    // Check if anime is in favorites
    final isFav = await _dbService.isFavorite(widget.anime['id'], userId);
    setState(() => _isFavorite = isFav);
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
      if (_isFavorite) {
        await _dbService.removeFromFavorites(widget.anime['id']);
        // Also call API to remove from server
        // await _apiService.removeFavorite(widget.anime['id'], authProvider.token!);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dihapus dari favorit')));
        }
      } else {
        await _dbService.addToFavorites(widget.anime['id'], userId);
        // Also call API to add to server
        // await _apiService.addFavorite(widget.anime['id'], authProvider.token!);

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
