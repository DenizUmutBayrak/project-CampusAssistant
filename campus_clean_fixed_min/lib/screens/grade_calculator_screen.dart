import 'package:flutter/material.dart';

class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class _GradeCalculatorScreenState extends State<GradeCalculatorScreen> {
  final TextEditingController _midtermCtrl = TextEditingController();
  final TextEditingController _finalCtrl = TextEditingController();

  double? result;

  String _getLetter(double score) {
    if (score >= 90) return "AA";
    if (score >= 85) return "BA";
    if (score >= 80) return "BB";
    if (score >= 75) return "CB";
    if (score >= 65) return "CC";
    if (score >= 55) return "DC";
    if (score >= 50) return "DD";
    return "FF";
  }

  void _calculateGrade() {
    final mid = double.tryParse(_midtermCtrl.text) ?? 0;
    final fin = double.tryParse(_finalCtrl.text) ?? 0;

    final grade = mid * 0.4 + fin * 0.6;

    setState(() {
      result = grade;
    });
  }

  @override
  void dispose() {
    _midtermCtrl.dispose();
    _finalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grade Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _midtermCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Midterm Grade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _finalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Final Grade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateGrade,
                child: const Text('Calculate'),
              ),
            ),
            const SizedBox(height: 20),
            if (result != null) ...[
              Text(
                "Final Score: ${result!.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Letter Grade: ${_getLetter(result!)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
