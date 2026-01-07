import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../main.dart';

class AddAnimePage extends StatefulWidget {
  const AddAnimePage({Key? key}) : super(key: key);

  @override
  State<AddAnimePage> createState() => _AddAnimePageState();
}

class _AddAnimePageState extends State<AddAnimePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _genreController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _trailerUrlController = TextEditingController();
  final _ratingController = TextEditingController();
  final _releaseDateController = TextEditingController();
  bool _isLoading = false;

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final animeData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'genre': _genreController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'trailer_url': _trailerUrlController.text.trim(),
        'rating': double.tryParse(_ratingController.text) ?? 0.0,
        'release_date': _releaseDateController.text.trim(),
      };

      Map<String, dynamic>? serverResponse;

      // Only call API when authenticated and token is available
      if (authProvider.isAuthenticated && authProvider.token != null) {
        try {
          serverResponse = await ApiService().createAnime(
            animeData,
            authProvider.token!,
          );
        } catch (apiErr) {
          // ignore API error, we'll still save locally
          serverResponse = null;
          print('API create failed: $apiErr');
        }
      }

      // Also save to local database; include created_at and any server id if returned
      final dbService = DatabaseService();
      final localAnimeData = {
        ...animeData,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (serverResponse != null) {
        // Try to extract id from common response shapes
        final sid =
            (serverResponse['data'] is Map &&
                serverResponse['data']['id'] != null)
            ? serverResponse['data']['id']
            : serverResponse['id'];
        if (sid != null) {
          localAnimeData['server_id'] = sid;
        }
      }

      final insertedId = await dbService.insertAnime(localAnimeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anime berhasil ditambahkan')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambahkan anime: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Anime Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Anime',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Sinopsis',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sinopsis tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Genre tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'URL gambar tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _trailerUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Trailer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _releaseDateController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Rilis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Tambah Anime'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
