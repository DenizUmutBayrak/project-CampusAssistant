import 'package:flutter/material.dart';
import '../db/app_db.dart';

class ExamsScreen extends StatefulWidget {
  final String studentId;
  const ExamsScreen({super.key, required this.studentId});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  DateTime? _parseDT(String dateRaw, String timeRaw) {
    try {
      // Supports: 2026-01-15, 15.01.2026, 1/15/26, 1/15/2026
      String d = dateRaw.trim();
      if (d.contains('T')) d = d.split('T').first;
      d = d.split(' ').first;

      if (d.contains('.')) {
        final p = d.split('.');
        if (p.length == 3) {
          d = "${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}";
        }
      } else if (d.contains('/')) {
        final p = d.split('/').map((e) => e.trim()).toList();
        if (p.length == 3) {
          int a = int.tryParse(p[0]) ?? 0;
          int b = int.tryParse(p[1]) ?? 0;
          int y = int.tryParse(p[2]) ?? 0;
          if (y < 100) y = 2000 + y;
          int month, day;
          if (a > 12) {
            day = a;
            month = b;
          } else {
            month = a;
            day = b;
          }
          d = "${y.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
        }
      }

      String t = timeRaw.trim().replaceAll('.', ':');
      if (t.isEmpty) t = '00:00';
      final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t);
      if (m == null) t = '00:00';
      if (m != null) t = "${m.group(1)!.padLeft(2, '0')}:${m.group(2)!}";

      return DateTime.parse('$d $t:00');
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadExams({bool spinner = true}) async {
    if (spinner)
      setState(() {
        _loading = true;
        _error = null;
      });

    try {
      final db = await AppDb.instance.db;
      final rows = await db.query(
        'exams',
        where: 'studentId = ?',
        whereArgs: [widget.studentId],
      );

      final mutableRows = List<Map<String, dynamic>>.from(rows);
      mutableRows.sort((a, b) {
        final ad = _parseDT(a['date'].toString(), a['time'].toString());
        final bd = _parseDT(b['date'].toString(), b['time'].toString());
        if (ad == null || bd == null) return 0;
        return ad.compareTo(bd);
      });

      if (!mounted) return;
      setState(() {
        _rows = mutableRows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exams'),
        actions: [
          IconButton(
            onPressed: () => _loadExams(spinner: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Exams couldn't load.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_error!),
                  ElevatedButton(
                    onPressed: _loadExams,
                    child: const Text("Try Again"),
                  ),
                ],
              ),
            )
          : _rows.isEmpty
          ? const Center(child: Text("No exams found."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final e = _rows[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.event)),
                    title: Text(e['course'] ?? ''),
                    subtitle: Text(
                      "${e['date']} • ${e['time']} • ${e['room']}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
