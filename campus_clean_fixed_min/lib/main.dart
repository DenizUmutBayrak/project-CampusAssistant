import 'package:flutter/material.dart';
import 'db/app_db.dart';
import 'db/excel_importer.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ 1) Eski DB'yi sil (targets tablosu eksik olduğu için importer çöküyordu)
    await AppDb.instance.hardReset();

    // ✅ 2) Yeni DB'yi oluştur (version 2 + targets tablosu)
    final db = await AppDb.instance.db;

    // ✅ 3) CSV'leri içeri aktar
    await ExcelImporter.importExcel();

    Future<void> logCount(String table) async {
      try {
        final r = await db.rawQuery('SELECT COUNT(*) as c FROM $table');
        debugPrint('COUNT[$table]=${r.first['c']}');
      } catch (e) {
        debugPrint('COUNT[$table]=ERROR ($e)');
      }
    }

    await logCount('students');
    await logCount('teachers');
    await logCount('schedule');
    await logCount('teacher_schedule');
    await logCount('grades');
    await logCount('exams');
    await logCount('announcements');
    await logCount('targets');

    debugPrint("BOOT: Sistem başarıyla başlatıldı ve veriler yüklendi.");
  } catch (e, st) {
    debugPrint("BOOT: Başlatma sırasında hata: $e");
    debugPrint("BOOT: StackTrace:\n$st");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Assistant',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}
