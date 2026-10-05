import 'package:sqflite/sqflite.dart';
import 'app_db.dart';

class SeedData {
  static Future<void> ensureSeeded() async {
    final database = await AppDb.instance.db;

    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM students'),
    );

    if ((count ?? 0) > 0) return;

    await database.insert('students', {
      'studentId': '2103021261',
      'name': 'Türkü Çağlar',
      'password': '1234',
    });

    await database.insert('students', {
      'studentId': '2103029999',
      'name': 'Demo Student',
      'password': '1234',
    });

    // Schedule - Türkü
    await database.insert('schedule', {
      'studentId': '2103021261',
      'day': 'Wed',
      'start': '08:00',
      'end': '10:50',
      'course': 'Mobile Application Programming',
      'room': 'AYZ.UE',
      'instructor': 'Onur Kardeş',
    });

    await database.insert('schedule', {
      'studentId': '2103021261',
      'day': 'Thu',
      'start': '09:00',
      'end': '11:50',
      'course': 'Data Mining',
      'room': 'AYZ.223',
      'instructor': 'S. Serdar Yörük',
    });

    // Schedule - Demo Student (farklı)
    await database.insert('schedule', {
      'studentId': '2103029999',
      'day': 'Mon',
      'start': '10:00',
      'end': '11:50',
      'course': 'Computer Vision',
      'room': 'AYZ.E1-110',
      'instructor': 'Ediz Saykol',
    });

    // Grades
    await database.insert('grades', {
      'studentId': '2103021261',
      'course': 'Data Mining',
      'midterm': 72,
      'final': 80,
      'letter': 'BB',
    });

    await database.insert('grades', {
      'studentId': '2103029999',
      'course': 'Computer Vision',
      'midterm': 55,
      'final': 60,
      'letter': 'CC',
    });

    // Exams
    await database.insert('exams', {
      'studentId': '2103021261',
      'course': 'Mobile Application Programming',
      'date': '2026-02-20',
      'time': '10:00',
      'room': 'AYZ.UE',
    });

    await database.insert('exams', {
      'studentId': '2103029999',
      'course': 'Computer Vision',
      'date': '2026-02-25',
      'time': '14:00',
      'room': 'AYZ.E1-110',
    });
  }
}
