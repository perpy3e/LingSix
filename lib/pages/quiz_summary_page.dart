import 'package:flutter/material.dart';

class QuizSummaryPage extends StatelessWidget {
  final int correct;
  final int total;
  final String quizId;

  const QuizSummaryPage({
    super.key,
    required this.correct,
    required this.total,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Summary'),
        leading: BackButton(onPressed: () => Navigator.pushReplacementNamed(context, '/home')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Quiz: $quizId', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Text('Score: $correct / $total', style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'Accuracy: ${(total > 0) ? ((correct / total) * 100).toStringAsFixed(1) : '0'}%',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
