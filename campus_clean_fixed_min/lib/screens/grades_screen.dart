import 'package:flutter/material.dart';
import '../db/app_db.dart';

class GradesScreen extends StatefulWidget {
  final String studentId;
  const GradesScreen({super.key, required this.studentId});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  double? _gpa;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  double _letterToPoint(String letter) {
    switch (letter.toUpperCase().trim()) {
      case 'AA':
        return 4.0;
      case 'BA':
        return 3.5;
      case 'BB':
        return 3.0;
      case 'CB':
        return 2.5;
      case 'CC':
        return 2.0;
      case 'DC':
        return 1.5;
      case 'DD':
        return 1.0;
      case 'FD':
        return 0.5;
      case 'FF':
        return 0.0;
      default:
        return 0.0;
    }
  }

  Future<void> _loadGrades({bool spinner = true}) async {
    if (spinner) setState(() => _loading = true);

    final db = await AppDb.instance.db;
    final rows = await db.query(
      'grades',
      where: 'studentId = ?',
      whereArgs: [widget.studentId],
      orderBy: 'course ASC',
    );

    double sum = 0;
    int n = 0;
    for (final r in rows) {
      final letter = (r['letter'] ?? '').toString();
      if (letter.isEmpty) continue;
      sum += _letterToPoint(letter);
      n += 1;
    }

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _gpa = n == 0 ? null : (sum / n);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final header = Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.school)),
        title: const Text('GPA'),
        subtitle: Text(
          _gpa == null ? 'Not available' : _gpa!.toStringAsFixed(2),
        ),
      ),
    );

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => _loadGrades(spinner: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                header,
                const SizedBox(height: 12),
                if (_rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 140),
                    child: Center(child: Text('No grades found.')),
                  )
                else
                  ..._rows.map((g) {
                    final course = (g['course'] ?? '') as String;
                    final mid = g['midterm'];
                    final fin = g['final'];
                    final letter = (g['letter'] ?? '-') as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.star)),
                        title: Text(
                          course,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          'Midterm: ${mid ?? '-'}  |  Final: ${fin ?? '-'}',
                        ),
                        trailing: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Grades'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadGrades(spinner: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}
