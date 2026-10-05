import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'teacher_messages_screen.dart';
import 'teacher_schedule_screen.dart';
import 'add_announcement_screen.dart';
import 'manage_announcements_screen.dart';

class TeacherHomeScreen extends StatelessWidget {
  final String teacherId;
  const TeacherHomeScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Academian Portal"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 25),
          const Text(
            "Management Menu",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 15),

          // 1. DERS PROGRAMI
          _menuItem(
            context,
            "Class Schedule",
            "View your weekly teaching hours",
            Icons.calendar_today_rounded,
            Colors.orange, // Burada hata alıyorsan virgülleri kontrol et
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherScheduleScreen(teacherId: teacherId),
              ),
            ),
          ),

          // 2. YENİ DUYURU
          _menuItem(
            context,
            "New Announcement",
            "Broadcast a message to students",
            Icons.campaign_rounded, // Hatalı ikon değiştirildi
            Colors.purple, // Renk kullanımı düzeltildi
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddAnnouncementScreen(teacherId: teacherId),
              ),
            ),
          ),

          // 3. DUYURU YÖNETİMİ
          _menuItem(
            context,
            "Manage Announcements",
            "Edit or delete your previous posts",
            Icons.edit_note_rounded,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManageAnnouncementsScreen(teacherId: teacherId),
              ),
            ),
          ),

          // 4. MESAJLAR
          _menuItem(
            context,
            "Messages",
            "View student inquiries",
            Icons.message_rounded,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherMessagesScreen(teacherId: teacherId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.psychology, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome back,",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                "ID: $teacherId",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
