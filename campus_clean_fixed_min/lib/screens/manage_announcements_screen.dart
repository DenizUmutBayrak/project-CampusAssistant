import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../db/excel_exporter.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  final String teacherId;
  const ManageAnnouncementsScreen({super.key, required this.teacherId});

  @override
  State<ManageAnnouncementsScreen> createState() =>
      _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  List<Map<String, dynamic>> _myAnnouncements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final db = await AppDb.instance.db;
    final res = await db.query(
      'announcements',
      where: 'teacherId = ?',
      whereArgs: [widget.teacherId.trim()],
      orderBy: 'date DESC',
    );
    setState(() {
      _myAnnouncements = res;
      _isLoading = false;
    });
  }

  Future<void> _deleteAnnouncement(int id) async {
    final db = await AppDb.instance.db;

    // 1. Veritabanından sil
    await db.delete('announcements', where: 'id = ?', whereArgs: [id]);

    // 2. CSV dosyasını güncelle (Senkronizasyon)
    await ExcelExporter.exportAnnouncements();

    // 3. Listeyi yenile
    _fetchAnnouncements();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Duyuru silindi ve Excel güncellendi.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Duyurularımı Yönet")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myAnnouncements.isEmpty
          ? const Center(child: Text("Henüz bir duyuru yayınlamadınız."))
          : ListView.builder(
              itemCount: _myAnnouncements.length,
              itemBuilder: (context, index) {
                final item = _myAnnouncements[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      item['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${item['targetCourse']}\n${item['date']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      onPressed: () =>
                          _showDeleteDialog(item['id'], item['title']),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(int id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Duyuruyu Sil"),
        content: Text(
          "'$title' başlıklı duyuruyu silmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAnnouncement(id);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
