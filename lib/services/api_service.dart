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
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
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
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
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
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to load anime');
      }
    } catch (e) {
      throw Exception('Get anime error: $e');
    }
  }

  Future<Map<String, dynamic>> getAnimeById(int id, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getAnimeById}?id=$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
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
        return data['data'] ?? [];
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      throw Exception('Search error: $e');
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