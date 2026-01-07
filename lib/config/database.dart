import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseConfig {
  static final DatabaseConfig instance = DatabaseConfig._init();
  static Database? _database;

  DatabaseConfig._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('anime_collection.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add mal_id column to anime table
      await db.execute('ALTER TABLE anime ADD COLUMN mal_id INTEGER');
    }

    if (oldVersion < 3) {
      // Add server_id column to store backend ID for created items
      await db.execute('ALTER TABLE anime ADD COLUMN server_id INTEGER');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Tabel Users (cache dari API)
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType,
        email $textType,
        token $textType,
        created_at $textType
      )
    ''');

    // Tabel Anime (cache dari API)
    await db.execute('''
        CREATE TABLE anime (
        id $idType,
        title $textType,
        description $textType,
        genre $textType,
        rating $realType,
        image_url $textType,
        trailer_url $textType,
        release_date $textType,
        mal_id INTEGER,
        server_id INTEGER,
        is_favorite INTEGER DEFAULT 0,
        created_at $textType
      )
    ''');

    // Tabel Favorites (lokal)
    await db.execute('''
      CREATE TABLE favorites (
        id $idType,
        anime_id $intType,
        user_id $intType,
        created_at $textType,
        FOREIGN KEY (anime_id) REFERENCES anime (id)
      )
    ''');

    // Tabel Notifications
    await db.execute('''
      CREATE TABLE notifications (
        id $idType,
        title $textType,
        body $textType,
        anime_id INTEGER,
        is_read INTEGER DEFAULT 0,
        created_at $textType
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
