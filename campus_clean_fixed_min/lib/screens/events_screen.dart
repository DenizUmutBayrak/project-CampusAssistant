import 'package:flutter/material.dart';
import '../db/app_db.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  /// Veritabanından duyuruları çeker, tablo boşsa örnek veriler sunar.
  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final db = await AppDb.instance.db;
      final res = await db.query('announcements', orderBy: 'id DESC');

      if (res.isEmpty) {
        // Tablo boşsa kullanıcıya gösterilecek varsayılan veriler
        _announcements = [
          {
            'title': 'Sınav Programı Güncellemesi',
            'content':
                'Şubat ayı final sınav programı My Exams sekmesine eklenmiştir. Lütfen kontrol ediniz.',
            'author': 'Öğrenci İşleri',
            'date': '2026-01-12',
          },
          {
            'title': 'Kütüphane Çalışma Saatleri',
            'content':
                'Sınav haftası boyunca kütüphanemiz 7/24 hizmet verecektir.',
            'author': 'Kütüphane Yönetimi',
            'date': '2026-01-13',
          },
          {
            'title': 'Yapay Zeka Konferansı',
            'content':
                'Yarın saat 14:00\'te A Blok Konferans Salonu\'nda "Geleceğin Teknolojileri" konulu bir seminer verilecektir.',
            'author': 'Dr. Mehmet Demir',
            'date': '2026-01-13',
          },
        ];
      } else {
        _announcements = res;
      }
    } catch (e) {
      debugPrint("Duyuru yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnnouncements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnnouncements,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final item = _announcements[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.campaign, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            item['content'] ?? 'No Content',
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "By: ${item['author'] ?? 'Admin'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              Text(
                                item['date'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
