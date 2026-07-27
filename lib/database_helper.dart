import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ecofleet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabel untuk Menyimpan History / Aktivitas (BBM & Sampah)
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        time TEXT NOT NULL,
        detail TEXT NOT NULL,
        iconCode INTEGER NOT NULL
      )
    ''');

    // Tabel untuk Menyimpan Profil Pengguna
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY,
        nama TEXT,
        jabatan TEXT,
        nip TEXT,
        kontak TEXT,
        fotoProfil TEXT
      )
    ''');

    // Masukkan data profil awal (default)
    await db.insert('profile', {
      'id': 1,
      'nama': 'Budi Santoso',
      'jabatan': 'Fleet Driver Senior',
      'nip': 'EMP-2024-089',
      'kontak': '+62 812-3456-7890',
      'fotoProfil': 'https://i.pravatar.cc/150?img=12'
    });
  }

  // --- OPERASI TABEL ACTIVITIES ---
  
  Future<int> insertActivity(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('activities', row);
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    final db = await instance.database;
    // Urutkan dari yang terbaru (ID terbesar ke terkecil)
    return await db.query('activities', orderBy: 'id DESC');
  }

  // --- OPERASI TABEL PROFILE ---

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await instance.database;
    final results = await db.query('profile', limit: 1);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updateProfile(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('profile', row, where: 'id = ?', whereArgs: [1]);
  }
}