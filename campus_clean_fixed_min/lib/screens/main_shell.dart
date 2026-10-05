import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'cafeteria_screen.dart';
import 'profile_screen.dart';
import 'events_screen.dart';

class MainShell extends StatefulWidget {
  final String studentId;
  const MainShell({super.key, required this.studentId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(studentId: widget.studentId),
      ScheduleScreen(studentId: widget.studentId),
      const EventsScreen(),
      const CafeteriaScreen(),
      ProfileScreen(studentId: widget.studentId),
    ];

    return Scaffold(
      // IndexedStack sayesinde sayfalar arası geçişte veri/kaydırma pozisyonu kaybolmaz
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type:
            BottomNavigationBarType.fixed, // iOS'ta simgelerin kaymasını önler
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Food'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
