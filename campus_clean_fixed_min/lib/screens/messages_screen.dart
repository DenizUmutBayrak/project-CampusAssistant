import 'dart:typed_data'; // <--- BU SATIRI EKLEYİN
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart'; 
import '../db/app_db.dart';

class MessagesScreen extends StatefulWidget {
  final String studentId;
  const MessagesScreen({super.key, required this.studentId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _msgCtrl = TextEditingController();
  String? _selectedInstructor; 
  List<String> _instructorList = []; 
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _readInstructorsFromExcel();
    await _loadMessages();
  }

  Future<void> _readInstructorsFromExcel() async {
    try {
      // Excel dosyasından hocaları çekiyoruz
      ByteData data = await rootBundle.load("assets/sample.xlsx");
      var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      var excel = Excel.decodeBytes(bytes);

      List<String> names = [];
      var table = excel.tables['teachers']; 
      
      if (table != null) {
        for (int i = 1; i < table.maxRows; i++) {
          var row = table.rows[i];
          if (row.length > 1 && row[1] != null) {
            String val = row[1]!.value.toString().trim();
            if (val != "null" && val.isNotEmpty) {
              names.add(val);
            }
          }
        }
      }

      names = names.toSet().toList();

      if (mounted) {
        setState(() {
          _instructorList = names;
          if (_instructorList.isNotEmpty) {
            _selectedInstructor = _instructorList[0];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Excel Okuma Hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    final db = await AppDb.instance.db;
    if (_selectedInstructor == null) {
      if (mounted) setState(() => _messages = []);
      return;
    }

    // Conversation rule:
    // - Student -> Teacher: senderId=studentId, receiverName=teacherName
    // - Teacher -> Student: senderId=teacherName, receiverName=studentId
    final rows = await db.query(
      'messages',
      where:
          '(senderId = ? AND receiverName = ?) OR (senderId = ? AND receiverName = ?)',
      whereArgs: [
        widget.studentId,
        _selectedInstructor,
        _selectedInstructor,
        widget.studentId,
      ],
      orderBy: 'id ASC',
    );
    if (mounted) {
      setState(() {
        _messages = List.from(rows);
      });
    }
  }

  Future<void> _sendMessage() async {
    final msgText = _msgCtrl.text.trim();
    if (msgText.isEmpty || _selectedInstructor == null) return;

    try {
      final db = await AppDb.instance.db;
      // DİKKAT: 'message' yerine 'content' kullanıyoruz (app_db.dart ile uyumlu)
      await db.insert('messages', {
        'senderId': widget.studentId,
        'receiverName': _selectedInstructor,
        'content': msgText, // BURASI DÜZELDİ
        'timestamp': DateTime.now().toString().substring(0, 16),
      });
      
      _msgCtrl.clear();
      await _loadMessages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mesaj gönderildi!")),
        );
      }
    } catch (e) {
      debugPrint("Mesaj Gönderme Hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hoca Mesajlaşma")),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedInstructor,
                  items: _instructorList.map((name) => DropdownMenuItem(
                    value: name, 
                    child: Text(name)
                  )).toList(),
                  onChanged: (v) async {
                    setState(() => _selectedInstructor = v);
                    await _loadMessages();
                  },
                  decoration: const InputDecoration(labelText: "Hoca Seçin", contentPadding: EdgeInsets.all(10)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isMe = m['senderId'] == widget.studentId;
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMe ? "Ben" : "${m['senderId']}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(m['content'] ?? ""), // BURASI DÜZELDİ
                              const SizedBox(height: 4),
                              Text(m['timestamp'] ?? "", style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _msgCtrl)),
                      IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}