import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDb {
  static final AppDb instance = AppDb._init();
  static Database? _database;

  AppDb._init();

  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await _initDB('campus.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Eski kurulumlarda eksik tabloları ekle
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS targets(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              studentId TEXT,
              targetCourse TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(
        'CREATE TABLE students(studentId TEXT PRIMARY KEY, password TEXT, name TEXT)');
    await db.execute(
        'CREATE TABLE teachers(teacherId TEXT PRIMARY KEY, name TEXT, password TEXT, department TEXT)');
    await db.execute(
        'CREATE TABLE schedule(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId TEXT, day TEXT, start TEXT, end TEXT, course TEXT, room TEXT, instructor TEXT)');
    await db.execute(
        'CREATE TABLE grades(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId TEXT, course TEXT, midterm INTEGER, final INTEGER, letter TEXT)');
    await db.execute(
        'CREATE TABLE teacher_schedule(id INTEGER PRIMARY KEY AUTOINCREMENT, teacherId TEXT, courseName TEXT, day TEXT, start TEXT, end TEXT, room TEXT)');
    await db.execute(
        'CREATE TABLE exams(id INTEGER PRIMARY KEY AUTOINCREMENT, studentId TEXT, course TEXT, date TEXT, time TEXT, room TEXT)');
    await db.execute(
        'CREATE TABLE announcements(id INTEGER PRIMARY KEY AUTOINCREMENT, teacherId TEXT, title TEXT, content TEXT, date TEXT, targetCourse TEXT)');
    await db.execute(
        'CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, senderId TEXT, receiverName TEXT, content TEXT, timestamp TEXT)');

    // ✅ Eksik olan tablo: targets
    await db.execute('''
      CREATE TABLE targets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId TEXT,
        targetCourse TEXT
      )
    ''');

    // VIP öğrenci
    await db.insert(
      'students',
      {
        'studentId': '2103021261',
        'password': '1234',
        'name': 'Ebrar',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> loginStudent(String id, String password) async {
    final dbClient = await instance.db;

    final res = await dbClient.query(
      'students',
      where: 'studentId = ? AND password = ?',
      whereArgs: [id.trim(), password.trim()],
    );

    if (res.isNotEmpty) return res.first;

    // VIP fallback
    if (id.trim() == '2103021261' && password.trim() == '1234') {
      return {
        'studentId': '2103021261',
        'password': '1234',
        'name': 'Ebrar',
      };
    }

    return null;
  }

  Future<Map<String, dynamic>?> loginTeacher(String id, String password) async {
    final dbClient = await instance.db;

    // admin fallback
    if (id.trim() == 'admin' && password.trim() == 'admin') {
      return {'teacherId': 'admin', 'name': 'Admin Hoca', 'role': 'teacher'};
    }

    final res = await dbClient.query(
      'teachers',
      where: 'teacherId = ? AND password = ?',
      whereArgs: [id.trim(), password.trim()],
    );

    return res.isNotEmpty ? res.first : null;
  }

  Future<void> hardReset() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'campus.db');
    _database = null;
    await deleteDatabase(path);
  }
}
