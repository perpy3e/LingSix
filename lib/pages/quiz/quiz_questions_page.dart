import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/services/firestore_service.dart';
import 'package:lingsix/pages/quiz/quiz_result_page.dart';

class QuizQuestionsPage extends StatefulWidget {
  final String quizId;
  final String title;

  const QuizQuestionsPage({
    super.key,
    required this.quizId,
    required this.title,
  });

  @override
  State<QuizQuestionsPage> createState() => _QuizQuestionsPageState();
}

class _QuizQuestionsPageState extends State<QuizQuestionsPage> {
  final firestoreService = FirestoreService();
  final user = FirebaseAuth.instance.currentUser;

  int questionIndex = 0;
  int score = 0;

  bool answered = false;
  int correctChoice = 0;
  int? selectedChoice;

  Map<String, Map<String, int>> soundStats = {};

  final sounds = ["sh", "ss", "ah", "ee", "oo", "mm"];
  final random = Random();

  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();
    generateQuestions();
  }

  void generateQuestions() {
    questions = List.generate(12, (index) {
      final sound = sounds[random.nextInt(sounds.length)];

      return {
        "sound": sound,
        "correct": random.nextInt(4),
      };
    });
  }

  void selectAnswer(int index) {
    if (answered) return;

    final question = questions[questionIndex];
    correctChoice = question["correct"];
    selectedChoice = index;

    final sound = question["sound"];

    soundStats.putIfAbsent(sound, () => {
          "correct": 0,
          "total": 0,
        });

    soundStats[sound]!["total"] =
        soundStats[sound]!["total"]! + 1;

    if (index == correctChoice) {
      score++;
      soundStats[sound]!["correct"] =
          soundStats[sound]!["correct"]! + 1;
    }

    setState(() {
      answered = true;
    });

    Timer(const Duration(seconds: 1), nextQuestion);
  }

  void nextQuestion() {
    if (questionIndex < 11) {
      setState(() {
        questionIndex++;
        answered = false;
        selectedChoice = null;
      });
    } else {
      finishQuiz();
    }
  }

  Future<void> finishQuiz() async {
    final accuracy = (score / 12) * 100;

    if (user != null) {
      await firestoreService.saveQuizAttempt(
        uid: user!.uid,
        quizId: widget.quizId,
        score: score,
        totalQuestions: 12,
        accuracy: accuracy,
        perSoundAccuracy: soundStats,
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          score: score,
          total: 12,
          accuracy: accuracy,
        ),
      ),
    );
  }

  Color getButtonColor(int index) {
    if (!answered) return Colors.white;

    if (index == correctChoice) {
      return Colors.green;
    }

    if (index == selectedChoice) {
      return Colors.red;
    }

    return Colors.white;
  }

  String getEmoji(int index) {
    if (!answered) return "";

    if (index == correctChoice) return "✅";
    if (index == selectedChoice) return "❌";

    return "";
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[questionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.title} (${questionIndex + 1}/12)"),
        backgroundColor: AppColors.yellow600,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 100),
          ),

          const SizedBox(height: 40),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getButtonColor(index),
                  ),
                  onPressed: () => selectAnswer(index),
                  child: Text(
                    "${index + 1} ${getEmoji(index)}",
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
