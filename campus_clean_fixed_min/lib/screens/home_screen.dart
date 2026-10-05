import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../db/app_db.dart';
import 'login_screen.dart';
import 'schedule_screen.dart';
import 'grades_screen.dart';
import 'exams_screen.dart';
import 'ar_navigation_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  final String studentId;
  const HomeScreen({super.key, required this.studentId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  bool _loading = true;
  String _name = '';

  Map<String, dynamic>? _nextClass;
  Map<String, dynamic>? _nextExam;
  List<Map<String, dynamic>> _todayClasses = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await _loadProfile();
      await _loadDashboard();
    } catch (e) {
      debugPrint("Ana sayfa yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _auth.getProfile(widget.studentId.trim());
    debugPrint("Profil Verisi: $profile"); // Konsolda veriyi kontrol et
    if (mounted) {
      setState(() {
        _name = (profile?['name'] as String?) ?? '';
      });
    }
  }

  Future<void> _loadDashboard() async {
    final db = await AppDb.instance.db;
    final now = DateTime.now();
    final sId = widget.studentId.trim();

    // 1. SINAV VERİLERİ
    final exams = await db.query(
      'exams',
      where: 'studentId = ?',
      whereArgs: [sId],
    );
    
    List<Map<String, dynamic>> examList = List.from(exams);
    debugPrint("Sınav Sayısı: ${examList.length}");

    examList.sort((a, b) {
      final ad = _parseDate(a['date'].toString(), a['time'].toString());
      final bd = _parseDate(b['date'].toString(), b['time'].toString());
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });

    Map<String, dynamic>? foundExam;
    for (var e in examList) {
      final dt = _parseDate(e['date'].toString(), e['time'].toString());
      if (dt != null && dt.isAfter(now)) {
        foundExam = e;
        break;
      }
    }

    // 2. DERS PROGRAMI VERİLERİ
    final schedule = await db.query(
      'schedule',
      where: 'studentId = ?',
      whereArgs: [sId],
    );
    debugPrint("Ders Sayısı: ${schedule.length}");

    Map<String, dynamic>? foundClass;
    DateTime? bestDt;
    for (var r in schedule) {
      final dt = _nextOccurrence(
        r['day'].toString(),
        r['start'].toString(),
        now,
      );
      if (dt != null && (bestDt == null || dt.isBefore(bestDt))) {
        bestDt = dt;
        foundClass = r;
      }
    }

    // 3. BUGÜNKÜ DERSLER
    final todayKey = _weekdayKey(now.weekday);
    final todays = schedule
        .where((r) => r['day'].toString().trim() == todayKey)
        .toList();

    todays.sort(
      (a, b) => a['start'].toString().compareTo(b['start'].toString()),
    );

    if (mounted) {
      setState(() {
        _nextExam = foundExam;
        _nextClass = foundClass;
        _todayClasses = todays.take(3).toList();
      });
    }
  }

  DateTime? _parseDate(String dateStr, String timeStr) {
    try {
      // Supports:
      // - 2026-01-15
      // - 15.01.2026
      // - 1/15/26 (assets/exams.csv)
      // - 1/15/2026
      String d = dateStr.trim();
      if (d.contains('T')) d = d.split('T').first;

      if (d.contains('.')) {
        // dd.MM.yyyy
        final p = d.split('.');
        if (p.length == 3) {
          d = "${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}";
        }
      } else if (d.contains('/')) {
        // M/D/YY or M/D/YYYY (fallback to D/M/YY if first part > 12)
        final p = d.split('/').map((e) => e.trim()).toList();
        if (p.length == 3) {
          int a = int.tryParse(p[0]) ?? 0;
          int b = int.tryParse(p[1]) ?? 0;
          int y = int.tryParse(p[2]) ?? 0;

          if (y < 100) y = 2000 + y;

          int month, day;
          if (a > 12) {
            // D/M/Y
            day = a;
            month = b;
          } else {
            // M/D/Y (default)
            month = a;
            day = b;
          }

          d = "${y.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
        }
      }

      String t = timeStr.trim();
      // Accept HH:mm, H:mm, HH.mm etc.
      t = t.replaceAll('.', ':');
      final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t);
      if (m == null) t = "00:00";
      if (m != null) {
        final hh = m.group(1)!.padLeft(2, '0');
        final mm = m.group(2)!;
        t = "$hh:$mm";
      }

      return DateTime.parse("$d $t:00");
    } catch (_) {
      return null;
    }
  }

  String _weekdayKey(int w) => ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w];

  int _dayIndex(String d) => {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7}[d] ?? 1;

  DateTime? _nextOccurrence(String day, String start, DateTime now) {
    try {
      final p = start.split(':');
      if (p.length < 2) return null;
      int hour = int.parse(p[0]);
      int min = int.parse(p[1]);
      int target = _dayIndex(day.trim());
      int diff = target - now.weekday;
      if (diff < 0 || (diff == 0 && hour < now.hour)) diff += 7;
      return DateTime(now.year, now.month, now.day, hour, min).add(Duration(days: diff));
    } catch (_) {
      return null;
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _name.isEmpty ? "Student ${widget.studentId}" : _name;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $displayName'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : RefreshIndicator.adaptive(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "Next Class",
                          _nextClass?['course'] ?? "No Class",
                          _nextClass == null ? "-" : "${_nextClass!['day']} ${_nextClass!['start']}",
                          Icons.school_rounded,
                          () {
                            if (_nextClass != null) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ARNavigationScreen(initialRoom: _nextClass?['room'])));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          "Next Exam",
                          _nextExam?['course'] ?? "No Exam",
                          _nextExam == null ? "-" : "${_nextExam!['date'].toString().split('T').first}\n${_nextExam!['time']}",
                          Icons.event_note_rounded,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamsScreen(studentId: widget.studentId))),
                        ),
                      ),
                    ],
                  ),
                  if (_todayClasses.isNotEmpty) _buildTodaySection(),
                  const SizedBox(height: 24),
                  const Text("Quick Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _navCard('Messages', 'Contact instructors', Icons.forum_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen(studentId: widget.studentId)))),
                  _navCard('My Schedule', 'Weekly timetable', Icons.calendar_today_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleScreen(studentId: widget.studentId)))),
                  _navCard('My Grades', 'Academic results', Icons.grade_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => GradesScreen(studentId: widget.studentId)))),
                  _navCard('My Exams', 'Upcoming exams', Icons.assignment_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamsScreen(studentId: widget.studentId)))),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String title, String sub, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(sub, style: const TextStyle(fontSize: 11, color: Colors.blueGrey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySection() {
    return Card(
      margin: const EdgeInsets.only(top: 20),
      elevation: 0,
      color: Colors.orange.shade50.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.orange.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.today_rounded, size: 20, color: Colors.orange), SizedBox(width: 8), Text("Today's Classes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
            const Divider(),
            ..._todayClasses.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Text(c['start'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(child: Text("${c['course']} (${c['room']})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _navCard(String t, String s, IconData i, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(i, color: Colors.blueAccent)),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(s, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}