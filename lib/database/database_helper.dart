import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/recording_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'sleep_talk.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recordings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        file_size_bytes INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertRecording(RecordingModel recording) async {
    final db = await database;
    return await db.insert('recordings', recording.toMap());
  }

  Future<RecordingModel?> getRecordingById(int id) async {
    final db = await database;
    final maps = await db.query('recordings', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return RecordingModel.fromMap(maps.first);
  }

  Future<List<RecordingModel>> getAllRecordings() async {
    final db = await database;
    final maps = await db.query('recordings', orderBy: 'created_at DESC');
    return maps.map((map) => RecordingModel.fromMap(map)).toList();
  }

  Future<int> deleteRecording(int id) async {
    final db = await database;
    return await db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMultipleRecordings(List<int> ids) async {
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    return await db.delete(
      'recordings',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}