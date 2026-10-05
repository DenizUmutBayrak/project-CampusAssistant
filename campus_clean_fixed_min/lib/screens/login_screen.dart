import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'teacher_home_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;
  String _userRole = 'student';

  Future<void> _login() async {
    final id = _idCtrl.text.trim();
    final pass = _passCtrl.text.trim(); // Şifredeki boşlukları da temizle

    if (id.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter ID and Password")),
      );
      return;
    }

    // --- ACİL DURUM GİRİŞİ (HİÇBİR ŞEY ÇALIŞMAZSA BU ÇALIŞIR) ---
    // Eğer veritabanı bozuksa bile bu numarayla girmene izin verir
    if (id == '2103021261' && pass == '1234') {
       _git(id, 'student');
       return;
    }
    // ---------------------------------------------------------

    setState(() => _busy = true);
    final user = await _auth.login(id, pass, _userRole);
    setState(() => _busy = false);

    if (user != null) {
      _git(id, user['role']);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hatalı Giriş! Bilgilerinizi kontrol edin."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Yönlendirme işlemini yapan yardımcı fonksiyon
  void _git(String id, String role) {
    if (!mounted) return;
    if (role == 'teacher') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TeacherHomeScreen(teacherId: id)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainShell(studentId: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // Klavye açılınca ekranın kayması için
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Icon(Icons.school, size: 100, color: Colors.blue),
                const SizedBox(height: 32),
                
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'student', label: Text('Student'), icon: Icon(Icons.person)),
                    ButtonSegment(value: 'teacher', label: Text('Academian'), icon: Icon(Icons.psychology)),
                  ],
                  selected: {_userRole},
                  onSelectionChanged: (val) => setState(() => _userRole = val.first),
                ),

                const SizedBox(height: 32),
                TextField(
                  controller: _idCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "User ID",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _busy ? null : _login,
                    child: _busy
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}