import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbHelper {
  static final LocalDbHelper instance = LocalDbHelper._init();
  static Database? _database;

  LocalDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('laporan_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // v2: pastikan tabel pending_reports selalu ada. Database lama dibuat
    // dengan onCreate yang gagal diam-diam sehingga tabelnya tidak pernah
    // tercipta dan syncPendingReports melempar "no such table".
    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT,
        kategori_id INTEGER,
        kecamatan_id INTEGER,
        deskripsi TEXT,
        lokasi TEXT,
        latitude REAL,
        longitude REAL,
        foto_paths TEXT,
        created_at TEXT
      )
    ''');
  }

  Future<int> savePendingReport(Map<String, dynamic> report) async {
    final db = await instance.database;
    return await db.insert('pending_reports', report, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingReports() async {
    final db = await instance.database;
    return await db.query('pending_reports', orderBy: 'created_at ASC');
  }

  Future<int> deletePendingReport(int id) async {
    final db = await instance.database;
    return await db.delete('pending_reports', where: 'id = ?', whereArgs: [id]);
  }
}
