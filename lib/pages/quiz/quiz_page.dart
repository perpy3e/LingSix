import 'package:flutter/material.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/pages/quiz/quiz_questions_page.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  static final List<Map<String, dynamic>> quizzes =
      List.generate(10, (index) {
    return {
      "quizId": "quiz_${index + 1}",
      "title": "Quiz ${index + 1}",
      "topic": "LingSix Sound",
    };
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบ'),
        backgroundColor: AppColors.yellow600,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.yellow400, AppColors.yellow600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizQuestionsPage(
                      quizId: quiz["quizId"],
                      title: quiz["title"],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.quiz, size: 40),
                    const SizedBox(width: 16),
                    Text(
                      quiz["title"],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
