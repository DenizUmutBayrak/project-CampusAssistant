import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../db/excel_exporter.dart'; // CSV dışa aktarımı için

class AddAnnouncementScreen extends StatefulWidget {
  final String teacherId;
  const AddAnnouncementScreen({super.key, required this.teacherId});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String? _selectedCourse;
  List<String> _teacherCourses = [];
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherCourses();
  }

  // Akademisyenin verdiği dersleri veritabanından çekme
  Future<void> _loadTeacherCourses() async {
    final db = await AppDb.instance.db;
    final res = await db.query(
      'teacher_schedule',
      where: 'teacherId = ?',
      whereArgs: [widget.teacherId.trim()],
    );

    // Ders isimlerini listele ve tekrarları sil (unique)
    final courses = res.map((e) => e['courseName'].toString()).toSet().toList();

    setState(() {
      _teacherCourses = courses;
      if (courses.isNotEmpty) {
        _selectedCourse = courses.first;
      }
    });
  }

  // Duyuruyu Kaydetme ve Excel'e Yazma İşlemi
  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty ||
        _contentCtrl.text.isEmpty ||
        _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
      );
      return;
    }

    setState(() => _isBusy = true);

    try {
      final db = await AppDb.instance.db;

      // 1. Yerel SQL Veritabanına Kaydet
      await db.insert('announcements', {
        'teacherId': widget.teacherId,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'date': DateTime.now()
            .toString()
            .split('.')
            .first, // Örn: 2024-05-20 14:30:00
        'targetCourse': _selectedCourse,
      });

      // 2. Excel/CSV Senkronizasyonunu Tetikle (Export)
      // SQL'deki son hali alıp telefon hafızasına yazar
      await ExcelExporter.exportAnnouncements();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Duyuru başarıyla yayınlandı ve Excel'e senkronize edildi!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Sayfayı kapat
    } catch (e) {
      debugPrint("Kayıt Hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Announcement"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "New Announcement",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select a course and write your message.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Ders Seçimi Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCourse,
              decoration: InputDecoration(
                labelText: "Target Course",
                prefixIcon: const Icon(Icons.class_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _teacherCourses
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCourse = v),
            ),
            const SizedBox(height: 20),

            // Başlık Girişi
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: "Title",
                hintText: "e.g. Exam Date Postponed",
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // İçerik Girişi
            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: "Message Content",
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Yayınla Butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isBusy ? null : _save,
                icon: _isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text(
                  "PUBLISH & SYNC",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
