import 'package:flutter/material.dart';
import 'package:lingsix/pages/dashboard/dashboard_page.dart';
import 'package:lingsix/pages/quiz/quiz_page.dart';

class QuizResultPage extends StatelessWidget {
  final int score;
  final int total;
  final double accuracy;

  const QuizResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Result"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              "$score / $total",
              style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "Accuracy: ${accuracy.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DashboardPage(),
                  ),
                );
              },
              child: const Text("Dashboard"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const QuizPage(),
                  ),
                );
              },
              child: const Text("Back to Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}
