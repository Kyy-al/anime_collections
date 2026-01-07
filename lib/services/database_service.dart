import 'package:sqflite/sqflite.dart';
import '../config/database.dart';

class DatabaseService {
  Future<Database> get database async => await DatabaseConfig.instance.database;

  // ===== ANIME OPERATIONS =====

  Future<int> insertAnime(Map<String, dynamic> anime) async {
    final db = await database;
    return await db.insert('anime', anime);
  }

  Future<List<Map<String, dynamic>>> getAllAnime() async {
    final db = await database;
    return await db.query('anime', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getAnimeById(int id) async {
    final db = await database;
    final results = await db.query('anime', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getAnimeByMalId(int? malId) async {
    if (malId == null) return null;
    final db = await database;
    final results = await db.query(
      'anime',
      where: 'mal_id = ?',
      whereArgs: [malId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateAnime(int id, Map<String, dynamic> anime) async {
    final db = await database;
    return await db.update('anime', anime, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAnime(int id) async {
    final db = await database;
    return await db.delete('anime', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchAnime(String query) async {
    final db = await database;
    return await db.query(
      'anime',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }

  // Cache anime from API
  Future<void> cacheAnimeList(List<Map<String, dynamic>> animeList) async {
    final db = await database;
    final batch = db.batch();

    for (var anime in animeList) {
      batch.insert(
        'anime',
        anime,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // ===== FAVORITES OPERATIONS =====

  Future<int> addToFavorites(int animeId, int userId) async {
    final db = await database;
    return await db.insert('favorites', {
      'anime_id': animeId,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> removeFromFavorites(int animeId) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT a.* FROM anime a
      INNER JOIN favorites f ON a.id = f.anime_id
      WHERE f.user_id = ?
      ORDER BY f.created_at DESC
    ''',
      [userId],
    );
  }

  Future<bool> isFavorite(int animeId, int userId) async {
    final db = await database;
    final results = await db.query(
      'favorites',
      where: 'anime_id = ? AND user_id = ?',
      whereArgs: [animeId, userId],
    );
    return results.isNotEmpty;
  }

  // ===== USER OPERATIONS =====

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser() async {
    final db = await database;
    final results = await db.query('users', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    final id = user['id'] as int?;
    if (id == null) {
      // If no id provided, fallback to replacing entire users table entry
      return await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser() async {
    final db = await database;
    return await db.delete('users');
  }

  // ===== NOTIFICATION OPERATIONS =====

  Future<int> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.insert('notifications', notification);
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await database;
    return await db.query('notifications', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'is_read = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> markNotificationAsRead(int id) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  // ===== UTILITY =====

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('anime');
    await db.delete('favorites');
    await db.delete('notifications');
  }

  Future<void> close() async {
    await DatabaseConfig.instance.close();
  }
}
