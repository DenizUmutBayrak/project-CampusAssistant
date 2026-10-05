import 'package:flutter/material.dart';

import '../db/app_db.dart';

class TeacherMessagesScreen extends StatefulWidget {
  final String teacherId;
  const TeacherMessagesScreen({super.key, required this.teacherId});

  @override
  State<TeacherMessagesScreen> createState() => _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen> {
  final _msgCtrl = TextEditingController();

  bool _loading = true;
  String _teacherName = '';
  String? _selectedStudentId;

  List<String> _students = [];
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() => _loading = true);
    try {
      await _loadTeacherName();
      await _loadStudents();
      await _loadMessages();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTeacherName() async {
    final db = await AppDb.instance.db;
    final res = await db.query(
      'teachers',
      columns: ['name'],
      where: 'teacherId = ?',
      whereArgs: [widget.teacherId.trim()],
      limit: 1,
    );

    if (res.isNotEmpty) {
      _teacherName = (res.first['name']?.toString() ?? '').trim();
    }
    // admin fallback
    if (_teacherName.isEmpty && widget.teacherId.trim() == 'admin') {
      _teacherName = 'Admin Hoca';
    }
  }

  Future<void> _loadStudents() async {
    final db = await AppDb.instance.db;

    // Incoming: student -> teacherName
    final incoming = await db.rawQuery(
      'SELECT DISTINCT senderId FROM messages WHERE receiverName = ? ORDER BY senderId ASC',
      [_teacherName],
    );

    final ids = incoming
        .map((r) => (r['senderId']?.toString() ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    // If teacher has replied before, conversation still should show
    final outgoing = await db.rawQuery(
      'SELECT DISTINCT receiverName FROM messages WHERE senderId = ? ORDER BY receiverName ASC',
      [_teacherName],
    );

    final outIds = outgoing
        .map((r) => (r['receiverName']?.toString() ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    ids.addAll(outIds);

    ids.sort();
    if (!mounted) return;
    setState(() {
      _students = ids;
      _selectedStudentId ??= (_students.isNotEmpty ? _students.first : null);
    });
  }

  Future<void> _loadMessages() async {
    if (_teacherName.isEmpty || _selectedStudentId == null) {
      if (mounted) setState(() => _messages = []);
      return;
    }

    final db = await AppDb.instance.db;
    final rows = await db.query(
      'messages',
      where:
          '(senderId = ? AND receiverName = ?) OR (senderId = ? AND receiverName = ?)',
      whereArgs: [
        _selectedStudentId,
        _teacherName,
        _teacherName,
        _selectedStudentId,
      ],
      orderBy: 'id ASC',
    );

    if (!mounted) return;
    setState(() => _messages = List.from(rows));
  }

  Future<void> _sendReply() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || _teacherName.isEmpty || _selectedStudentId == null) return;

    final db = await AppDb.instance.db;
    await db.insert('messages', {
      'senderId': _teacherName,
      'receiverName': _selectedStudentId,
      'content': txt,
      'timestamp': DateTime.now().toString().substring(0, 16),
    });
    _msgCtrl.clear();
    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final title = _teacherName.isEmpty ? 'Messages' : 'Messages • $_teacherName';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() => _loading = true);
              await _loadStudents();
              await _loadMessages();
              if (mounted) setState(() => _loading = false);
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    items: _students
                        .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                        .toList(),
                    onChanged: (v) async {
                      setState(() => _selectedStudentId = v);
                      await _loadMessages();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
                Expanded(
                  child: _selectedStudentId == null
                      ? const Center(child: Text('No student messages yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final isMe = (m['senderId']?.toString() ?? '') == _teacherName;
                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? 'Ben (Hoca)' : (m['senderId']?.toString() ?? 'Öğrenci'),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(m['content']?.toString() ?? ''),
                                    const SizedBox(height: 4),
                                    Text(
                                      m['timestamp']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_selectedStudentId != null)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Reply…',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _sendReply,
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
