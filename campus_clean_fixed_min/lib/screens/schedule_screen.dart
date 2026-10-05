import 'package:flutter/material.dart';
import '../db/app_db.dart';

class ScheduleScreen extends StatefulWidget {
  final String studentId;
  const ScheduleScreen({super.key, required this.studentId});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Haftanın 7 günü
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _loading = true;

  // day -> lessons
  final Map<String, List<Map<String, dynamic>>> _lessonsByDay = {
    'Mon': [],
    'Tue': [],
    'Wed': [],
    'Thu': [],
    'Fri': [],
    'Sat': [],
    'Sun': [],
  };

  @override
  void initState() {
    super.initState();

    final initialIndex = _initialTabIndex();
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _loadSchedule();
  }

  int _initialTabIndex() {
    final now = DateTime.now();
    String todayKey;

    switch (now.weekday) {
      case DateTime.monday:
        todayKey = 'Mon';
        break;
      case DateTime.tuesday:
        todayKey = 'Tue';
        break;
      case DateTime.wednesday:
        todayKey = 'Wed';
        break;
      case DateTime.thursday:
        todayKey = 'Thu';
        break;
      case DateTime.friday:
        todayKey = 'Fri';
        break;
      case DateTime.saturday:
        todayKey = 'Sat';
        break;
      case DateTime.sunday:
        todayKey = 'Sun';
        break;
      default:
        todayKey = 'Mon';
    }

    final idx = _days.indexOf(todayKey);
    return idx == -1 ? 0 : idx;
  }

  // "08:00" gibi stringleri sıralamak için (HH:mm formatı şart)
  int _timeToMinutes(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  Future<void> _loadSchedule({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _loading = true);
    }

    final db = await AppDb.instance.db;

    final rows = await db.query(
      'schedule',
      where: 'studentId = ?',
      whereArgs: [widget.studentId],
      // orderBy'ı DB'de yapabiliriz ama day sırası/formatı bazen karışır.
      // orderBy: 'day ASC, start ASC',
    );

    // reset
    for (final d in _days) {
      _lessonsByDay[d] = [];
    }

    for (final r in rows) {
      final day = (r['day'] ?? '').toString().trim();

      // sadece beklediğimiz gün anahtarları
      if (_lessonsByDay.containsKey(day)) {
        _lessonsByDay[day]!.add(r);
      }
    }

    // her gün dersleri start saatine göre sırala
    for (final d in _days) {
      _lessonsByDay[d]!.sort((a, b) {
        final aStart = (a['start'] ?? '').toString();
        final bStart = (b['start'] ?? '').toString();
        return _timeToMinutes(aStart).compareTo(_timeToMinutes(bStart));
      });
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: () => _loadSchedule(showSpinner: false),
        child: TabBarView(
          controller: _tabController,
          children: _days.map((day) {
            final lessons = _lessonsByDay[day] ?? [];

            if (lessons.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Text(
                      "No classes defined for this day.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];

                final course = (lesson['course'] ?? '').toString();
                final dayStr = (lesson['day'] ?? '').toString();
                final start = (lesson['start'] ?? '').toString();
                final end = (lesson['end'] ?? '').toString();
                final room = (lesson['room'] ?? '').toString();
                final instructor = (lesson['instructor'] ?? '').toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.book)),
                    title: Text(
                      course,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "$dayStr • $start - $end  •  $room\n$instructor",
                      style: const TextStyle(height: 1.4),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }).toList(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Schedule"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadSchedule(showSpinner: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}
