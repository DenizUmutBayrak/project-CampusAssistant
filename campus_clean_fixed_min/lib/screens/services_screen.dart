import 'package:flutter/material.dart';

import 'schedule_screen.dart';
import 'grades_screen.dart';
import 'exams_screen.dart';
import 'cafeteria_screen.dart';
import 'grade_calculator_screen.dart';
import 'navigation_screen.dart';
import 'ar_navigation_screen.dart';

class ServicesScreen extends StatelessWidget {
  final String studentId;
  const ServicesScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Services")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            context,
            icon: Icons.schedule,
            title: "My Schedule",
            subtitle: "Weekly classes",
            page: ScheduleScreen(studentId: studentId),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            icon: Icons.star,
            title: "My Grades",
            subtitle: "Midterm / Final / Letter + GPA",
            page: GradesScreen(studentId: studentId),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            icon: Icons.calendar_today,
            title: "My Exams",
            subtitle: "Upcoming exams",
            page: ExamsScreen(studentId: studentId),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            icon: Icons.restaurant,
            title: "Cafeteria",
            subtitle: "Meals and menu",
            page: const CafeteriaScreen(),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            icon: Icons.calculate,
            title: "Grade Calculator",
            subtitle: "Calculate average",
            page: const GradeCalculatorScreen(),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            icon: Icons.map,
            title: "Directions",
            subtitle: "Campus map / rooms",
            page: const NavigationScreen(),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            icon: Icons.camera_alt,
            title: "AR Navigation",
            subtitle: "AR directions (device dependent)",
            page: const ARNavigationScreen(),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}
