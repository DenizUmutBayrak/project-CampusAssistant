import 'dart:typed_data'; // <--- BU SATIRI EKLEYİN
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart'; 
class TeacherScheduleScreen extends StatefulWidget {
  final String teacherId;
  const TeacherScheduleScreen({super.key, required this.teacherId});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _schedule = [];

  @override
  void initState() {
    super.initState();
    _fetchFromExcel();
  }

  Future<void> _fetchFromExcel() async {
    try {
      ByteData data = await rootBundle.load("assets/sample.xlsx");
      var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      var excel = Excel.decodeBytes(bytes);

      List<Map<String, dynamic>> tempSchedule = [];
      var table = excel.tables['teacher_schedule'];

      if (table != null) {
        for (int i = 1; i < table.maxRows; i++) {
          var row = table.rows[i];
          // Excel sütunları: teacherId(0), courseName(1), day(2), start(3), end(4), room(5)
          if (row.length > 5 && row[0]?.value.toString().trim() == widget.teacherId.trim()) {
            tempSchedule.add({
              'courseName': row[1]?.value.toString(),
              'day': row[2]?.value.toString(),
              'start': row[3]?.value.toString(),
              'end': row[4]?.value.toString(),
              'room': row[5]?.value.toString(),
            });
          }
        }
      }

      setState(() {
        _schedule = tempSchedule;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Ders programı yükleme hatası: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teaching Schedule")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schedule.isEmpty
              ? const Center(child: Text("No classes found for this ID"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schedule.length,
                  itemBuilder: (context, index) {
                    final s = _schedule[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.class_rounded, color: Colors.orange),
                        title: Text(s['courseName'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${s['day']} | ${s['start']} - ${s['end']}"),
                        trailing: Text(s['room'] ?? "", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
    );
  }
}