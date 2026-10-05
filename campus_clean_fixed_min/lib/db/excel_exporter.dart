import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'app_db.dart';

class ExcelExporter {
  static Future<String> exportAnnouncements() async {
    try {
      final db = await AppDb.instance.db;

      // 1. SQL'den verileri çek
      final List<Map<String, dynamic>> queryResult = await db.query(
        'announcements',
      );

      // 2. CSV başlıklarını ve verilerini hazırla
      List<List<dynamic>> rows = [];
      rows.add([
        "teacherId",
        "title",
        "content",
        "date",
        "targetCourse",
      ]); // Başlıklar

      for (var row in queryResult) {
        rows.add([
          row['teacherId'],
          row['title'],
          row['content'],
          row['date'],
          row['targetCourse'],
        ]);
      }

      // 3. Listeyi CSV string'ine dönüştür
      String csvContent = const ListToCsvConverter().convert(rows);

      // 4. Telefonun dokümanlar klasörünü bul
      final directory = await getApplicationDocumentsDirectory();
      final String path = "${directory.path}/announcements.csv";
      final File file = File(path);

      // 5. Dosyaya yaz
      await file.writeAsString(csvContent);

      print("Duyurular başarıyla dışa aktarıldı: $path");
      return path;
    } catch (e) {
      print("Export Hatası: $e");
      return "";
    }
  }
}
