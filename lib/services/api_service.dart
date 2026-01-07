import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.register),
            headers: ApiConfig.getHeaders(),
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Register failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Register error: $e');
    }
  }

  // Anime CRUD Methods
  Future<List<dynamic>> getAllAnime({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllAnime),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        // Enrich each anime with image, trailer, and mal_id from Jikan API
        final enriched = await Future.wait(
          list.map((e) async {
            try {
              final item = Map<String, dynamic>.from(e as Map);
              final title = (item['title'] ?? item['name'] ?? '') as String;
              if (title.isNotEmpty) {
                final jikanData = await _fetchJikanData(title);
                if (jikanData['image'] != null &&
                    jikanData['image']!.isNotEmpty) {
                  item['image_url'] = jikanData['image'];
                }
                if (jikanData['trailer'] != null &&
                    jikanData['trailer']!.isNotEmpty) {
                  item['trailer_url'] = jikanData['trailer'];
                }
                if (jikanData['mal_id'] != null) {
                  item['mal_id'] = jikanData['mal_id'];
                }
              }
              return item;
            } catch (_) {
              return e;
            }
          }),
        );

        return enriched;
      } else {
        throw Exception('Failed to load anime');
      }
    } catch (e) {
      throw Exception('Get anime error: $e');
    }
  }

  // Helper: search Jikan v4 for anime title and return image, trailer, and mal_id
  Future<Map<String, dynamic>> _fetchJikanData(String title) async {
    try {
      final query = Uri.encodeComponent(title);
      final url = 'https://api.jikan.moe/v4/anime?q=$query&limit=1';
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final results = data['data'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          String? imageUrl;
          // Try images.jpg.large_image_url -> images.jpg.image_url
          final images = first['images'] as Map<String, dynamic>?;
          if (images != null) {
            final jpg = images['jpg'] as Map<String, dynamic>?;
            if (jpg != null) {
              imageUrl = jpg['large_image_url'] ?? jpg['image_url'];
            }
          }
          // Fallback to image or other fields
          imageUrl ??= first['image_url'] as String?;

          String? trailerUrl;
          final trailer = first['trailer'] as Map<String, dynamic>?;
          if (trailer != null) {
            final youtubeId = trailer['youtube_id'] as String?;
            if (youtubeId != null && youtubeId.isNotEmpty) {
              trailerUrl = 'https://www.youtube.com/watch?v=$youtubeId';
            }
          }

          return {
            'image': imageUrl,
            'trailer': trailerUrl,
            'mal_id': first['mal_id'],
          };
        }
      }
    } catch (_) {
      // ignore errors, return null to let backend image remain
    }
    return {'image': null, 'trailer': null, 'mal_id': null};
  }

  Future<Map<String, dynamic>> getAnimeById(int id, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getAnimeById}?id=$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final item = data['data'] as Map<String, dynamic>;
        try {
          final title = (item['title'] ?? item['name'] ?? '') as String;
          if (title.isNotEmpty) {
            final jikanData = await _fetchJikanData(title);
            if (jikanData['image'] != null && jikanData['image']!.isNotEmpty) {
              item['image_url'] = jikanData['image'];
            }
            if (jikanData['trailer'] != null &&
                jikanData['trailer']!.isNotEmpty) {
              item['trailer_url'] = jikanData['trailer'];
            }
            if (jikanData['mal_id'] != null) {
              item['mal_id'] = jikanData['mal_id'];
            }
          }
        } catch (_) {}

        return item;
      } else {
        throw Exception('Failed to load anime detail');
      }
    } catch (e) {
      throw Exception('Get anime detail error: $e');
    }
  }

  Future<Map<String, dynamic>> createAnime(
    Map<String, dynamic> animeData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createAnime),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(animeData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create anime');
      }
    } catch (e) {
      throw Exception('Create anime error: $e');
    }
  }

  Future<Map<String, dynamic>> updateAnime(
    int id,
    Map<String, dynamic> animeData,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.updateAnime}?id=$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(animeData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update anime');
      }
    } catch (e) {
      throw Exception('Update anime error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteAnime(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.deleteAnime}?id=$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete anime');
      }
    } catch (e) {
      throw Exception('Delete anime error: $e');
    }
  }

  Future<List<dynamic>> searchAnime(String query, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.searchAnime}?q=$query'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        final enriched = await Future.wait(
          list.map((e) async {
            try {
              final item = Map<String, dynamic>.from(e as Map);
              final title = (item['title'] ?? item['name'] ?? '') as String;
              if (title.isNotEmpty) {
                final jikanData = await _fetchJikanData(title);
                if (jikanData['image'] != null &&
                    jikanData['image']!.isNotEmpty) {
                  item['image_url'] = jikanData['image'];
                }
                if (jikanData['trailer'] != null &&
                    jikanData['trailer']!.isNotEmpty) {
                  item['trailer_url'] = jikanData['trailer'];
                }
                if (jikanData['mal_id'] != null) {
                  item['mal_id'] = jikanData['mal_id'];
                }
              }
              return item;
            } catch (_) {
              return e;
            }
          }),
        );

        if (enriched.isNotEmpty) return enriched;

        // Fallback: jika backend kosong, cari langsung ke Jikan
        final jikanResults = await _searchJikan(query);
        if (jikanResults.isNotEmpty) return jikanResults;

        return enriched;
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }

  Future<List<dynamic>> _searchJikan(String query) async {
    try {
      final q = Uri.encodeComponent(query);
      final url = 'https://api.jikan.moe/v4/anime?q=$q&limit=12';
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final List<dynamic>? list = data['data'] as List<dynamic>?;
        if (list == null) return [];

        return list.map((raw) {
          try {
            final item = raw as Map<String, dynamic>;
            final title = item['title'] as String? ?? '';
            final synopsis = item['synopsis'] as String? ?? '';
            final score = (item['score'] is num) ? item['score'] : 0;
            String? imageUrl;
            try {
              final images = item['images'] as Map<String, dynamic>?;
              final jpg = images?['jpg'] as Map<String, dynamic>?;
              imageUrl = jpg?['large_image_url'] ?? jpg?['image_url'];
            } catch (_) {
              imageUrl = item['image_url'] as String?;
            }

            String genres = '';
            try {
              final gs = item['genres'] as List<dynamic>?;
              if (gs != null && gs.isNotEmpty) {
                genres = gs
                    .map((g) => (g['name'] ?? '') as String)
                    .where((s) => s.isNotEmpty)
                    .join(', ');
              }
            } catch (_) {}

            String? trailerUrl;
            try {
              final trailer = item['trailer'] as Map<String, dynamic>?;
              if (trailer != null) {
                final youtubeId = trailer['youtube_id'] as String?;
                if (youtubeId != null && youtubeId.isNotEmpty) {
                  trailerUrl = 'https://www.youtube.com/watch?v=$youtubeId';
                }
              }
            } catch (_) {}

            return {
              'mal_id': item['mal_id'],
              'title': title,
              'description': synopsis,
              'genre': genres,
              'rating': score,
              'image_url': imageUrl ?? '',
              'trailer_url': trailerUrl,
            };
          } catch (_) {
            return raw;
          }
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // Get anime episodes from Jikan API
  Future<List<Map<String, dynamic>>> getAnimeEpisodes(int malId) async {
    try {
      final url = 'https://api.jikan.moe/v4/anime/$malId/episodes';
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final List<dynamic>? episodes = data['data'] as List<dynamic>?;

        if (episodes == null) return [];

        return episodes.map((episode) {
          final ep = episode as Map<String, dynamic>;
          return {
            'mal_id': ep['mal_id'],
            'title': ep['title'] ?? 'Episode ${ep['mal_id']}',
            'title_japanese': ep['title_japanese'],
            'title_romanji': ep['title_romanji'],
            'aired': ep['aired'],
            'score': ep['score'],
            'filler': ep['filler'] ?? false,
            'recap': ep['recap'] ?? false,
            'url':
                'https://myanimelist.net/anime/$malId/episode/${ep['mal_id']}',
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching episodes: $e');
      return [];
    }
  }

  // Favorites Methods
  Future<List<dynamic>> getFavorites(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getFavorites),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      throw Exception('Get favorites error: $e');
    }
  }

  Future<Map<String, dynamic>> addFavorite(int animeId, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.addFavorite),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({'anime_id': animeId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add favorite');
      }
    } catch (e) {
      throw Exception('Add favorite error: $e');
    }
  }

  Future<Map<String, dynamic>> removeFavorite(int animeId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.removeFavorite}?anime_id=$animeId'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to remove favorite');
      }
    } catch (e) {
      throw Exception('Remove favorite error: $e');
    }
  }
}
