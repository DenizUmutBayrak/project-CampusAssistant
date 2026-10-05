import '../db/app_db.dart';

class AuthService {
  final _appDb = AppDb.instance;

  Future<Map<String, dynamic>?> login(
    String id,
    String pass,
    String selectedRole,
  ) async {
    // 1. Öğretmen/Akademisyen Girişi (Senin istediğin özel kural)
    if (selectedRole == 'teacher') {
      // Eğer ID 99 ile başlıyorsa ve şifre admin ise direkt girsin
      if (id.startsWith('99') && pass == 'admin') {
        return {
          'id': id, 
          'role': 'teacher', 
          'name': 'Academic Staff'
        };
      }
      return null; // Kurala uymuyorsa giriş yapamaz
    }

    // 2. Öğrenci Girişi (Excel'deki verilere bakar)
    final student = await _appDb.loginStudent(id, pass);

    if (student != null) {
      return {
        'id': id, 
        'role': 'student', 
        'name': student['name'] ?? id
      };
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProfile(String studentId) async {
    final db = await _appDb.db;
    final res = await db.query(
      'students',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  Future<void> logout() {
    return Future.value();
  }
}