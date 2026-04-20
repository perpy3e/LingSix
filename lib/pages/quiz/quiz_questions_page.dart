import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/router.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/providers/theme_provider.dart';
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
  final AudioPlayer _player = AudioPlayer();

  static const int questionsPerSet = 12;

  int questionIndex = 0;
  int score = 0;
  bool isLoading = true;

  Map<String, Map<String, int>> soundStats = {};

  final sounds = ["ah", "ee", "m", "oo", "s", "sh"];
  final random = Random();

  List<Map<String, String>> questions = [];

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> loadQuestions() async {
    final jsonString = await rootBundle.loadString('assets/data/vocabulary.json');
    final Map<String, dynamic> data = json.decode(jsonString);

    final generated = <Map<String, String>>[];

    for (final sound in sounds) {
      final words = (data[sound] as List<dynamic>).cast<String>().toList();
      words.shuffle(random);

      for (final word in words.take(2)) {
        generated.add({
          "sound": sound,
          "word": word,
          "image": "assets/content/vocabulary/$sound/$word/image.png",
          "audio": "content/vocabulary/$sound/$word/sound.mp3",
        });
      }
    }

    generated.shuffle(random);

    if (!mounted) return;
    setState(() {
      questions = generated;
      isLoading = false;
    });
  }

  Future<void> onAnswer({required bool isCheck}) async {
    final question = questions[questionIndex];
    final sound = question["sound"]!;

    soundStats.putIfAbsent(sound, () => {"correct": 0, "total": 0});
    soundStats[sound]!["total"] = soundStats[sound]!["total"]! + 1;

    if (isCheck) {
      score++;
      soundStats[sound]!["correct"] = soundStats[sound]!["correct"]! + 1;
    }

    if (questionIndex < questionsPerSet - 1) {
      setState(() {
        questionIndex++;
      });
    } else {
      await finishQuiz();
    }
  }

  Future<void> finishQuiz() async {
    final accuracy = (score / questionsPerSet) * 100;

    if (user != null) {
      await firestoreService.saveQuizAttempt(
        uid: user!.uid,
        quizId: widget.quizId,
        score: score,
        totalQuestions: questionsPerSet,
        accuracy: accuracy,
        perSoundAccuracy: soundStats,
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          score: score,
          total: questionsPerSet,
          accuracy: accuracy,
        ),
      ),
    );
  }

  Future<void> playCurrentWord() async {
    final audioPath = questions[questionIndex]["audio"]!;
    await _player.play(AssetSource(audioPath));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[questionIndex];

    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(themeProvider.getWallpaperPath('quiz')),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              size: 28,
                              color: AppColors.blue800,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRouter.soundSettings);
                            },
                          ),
                          const Spacer(),
                          Text(
                            "${widget.title} (${questionIndex + 1}/$questionsPerSet)",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue800,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 30,
                              color: AppColors.blue800,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "ออกเสียงถูกหรือไม่",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: playCurrentWord,
                      icon: const Icon(Icons.volume_up_rounded),
                      iconSize: 44,
                      color: AppColors.yellow700,
                      tooltip: "Play sound",
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Image.asset(
                        question["image"]!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text('Image not found'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => onAnswer(isCheck: true),
                            icon: const Icon(Icons.check_circle_outline, size: 28),
                            label: const Text(
                              "Check",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(64),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => onAnswer(isCheck: false),
                            icon: const Icon(Icons.cancel_outlined, size: 28),
                            label: const Text(
                              "Uncheck",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(64),
                              backgroundColor: Colors.grey.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
