import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:contact/models/contact.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String dbName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        company TEXT,
        email TEXT,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE my_info (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        company TEXT,
        email TEXT,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // 연락처 저장
  Future<void> insertContact(Contact contact) async {
    final db = await database;
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 연락처 전체 불러오기
  Future<List<Contact>> getContacts() async {
    final db = await database;
    final maps = await db.query('contacts');
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  // 연락처 수정
  Future<void> updateContact(Contact contact) async {
    final db = await database;
    await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  // 연락처 삭제
  Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // 사용자 정보 저장
  Future<void> saveMyInfo(Contact contact) async {
    final db = await database;
    await db.insert(
      'my_info',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 사용자 정보 불러오기
  Future<Contact?> getMyInfo() async {
    final db = await database;
    final maps = await db.query('my_info');
    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    }
    return null;
  }

  // 초기 실행 여부 저장
  Future<void> setInitialized(bool value) async {
    final db = await database;
    await db.insert('metadata', {
      'key': 'isInitialized',
      'value': value ? 'true' : 'false',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 초기 실행 여부 조회
  Future<bool> isInitialized() async {
    final db = await database;
    final maps = await db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: ['isInitialized'],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] == 'true';
    }
    return false;
  }

  // 검색어 저장
  Future<void> saveSearchQuery(String query) async {
    final db = await database;
    await db.insert('metadata', {
      'key': 'searchQuery',
      'value': query,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 검색어 불러오기
  Future<String?> getSearchQuery() async {
    final db = await database;
    final maps = await db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: ['searchQuery'],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }
}
