import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'app_db.dart';

class ExcelImporter {
  static Future<void> importExcel() async {
    final db = await AppDb.instance.db;

    final tables = [
      'students',
      'teachers',
      'schedule',
      'teacher_schedule',
      'grades',
      'exams',
      'announcements',
      'messages',
      'targets',
    ];

    // Verileri temizle
    for (final t in tables) {
      try {
        await db.delete(t);
      } catch (e) {
        // tablo yoksa vs. ignore
        // ignore: avoid_print
        print("$t tablosu temizlenemedi: $e");
      }
    }

    // Aktarımlar
    await _safeImport(db, 'assets/students.csv', 'students',
        ['studentId', 'password', 'name']);
    await _safeImport(db, 'assets/teachers.csv', 'teachers',
        ['teacherId', 'name', 'password', 'department']);
    await _safeImport(db, 'assets/schedule.csv', 'schedule',
        ['studentId', 'day', 'start', 'end', 'course', 'room', 'instructor']);
    await _safeImport(db, 'assets/teacher_schedule.csv', 'teacher_schedule',
        ['teacherId', 'courseName', 'day', 'start', 'end', 'room']);
    await _safeImport(db, 'assets/grades.csv', 'grades',
        ['studentId', 'course', 'midterm', 'final', 'letter']);
    await _safeImport(db, 'assets/exams.csv', 'exams',
        ['studentId', 'course', 'date', 'time', 'room']);
    await _safeImport(db, 'assets/announcements.csv', 'announcements',
        ['teacherId', 'title', 'content', 'date', 'targetCourse']);

    // ignore: avoid_print
    print("🚀 TÜM VERİLER BAŞARIYLA YÜKLENDİ");
  }

  static Future<void> _safeImport(
    Database db,
    String assetPath,
    String table,
    List<String> columns,
  ) async {
    int inserted = 0;

    try {
      final content = await rootBundle.loadString(assetPath);

      // CSV parsing: quoted alanlar + içindeki virgüller doğru okunur
      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(content);

      if (rows.isEmpty) {
        // ignore: avoid_print
        print("⚠️ $table: dosya boş ($assetPath)");
        return;
      }

      // 0. satır header, 1'den başla
      for (int i = 1; i < rows.length; i++) {
        final rowList = rows[i];

        // satır tamamen boş olabilir
        if (rowList.isEmpty) continue;

        // Satırı string’e çevirip trimle
        final values = rowList.map((v) => (v ?? '').toString().trim()).toList();

        // bazen sonda boş kolonlar olur; yine de lazım olan kadarını alacağız
        if (values.every((v) => v.isEmpty)) continue;

        // En az kolon sayısı kadar alan yoksa geç
        if (values.length < columns.length) continue;

        final row = <String, dynamic>{};

        for (int j = 0; j < columns.length; j++) {
          final col = columns[j];
          final val = values[j];

          if (table == 'grades' && (col == 'midterm' || col == 'final')) {
            row[col] = int.tryParse(val) ?? 0;
          } else {
            row[col] = val;
          }
        }

        await db.insert(table, row);
        inserted++;
      }

      // ignore: avoid_print
      print("✅ $table tablosu yüklendi. inserted=$inserted");
    } catch (e) {
      // ignore: avoid_print
      print("❌ Dosya okuma/parse hatası ($assetPath): $e");
    }
  }
}
