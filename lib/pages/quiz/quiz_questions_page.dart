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
    final jsonString = await rootBundle.loadString(
      'assets/data/vocabulary.json',
    );
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

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          score: score,
          total: questionsPerSet,
          accuracy: accuracy,
          perSoundAccuracy: soundStats,
        ),
      ),
    );
  }

  Future<void> playCurrentWord() async {
    final audioPath = questions[questionIndex]["audio"]!;
    await _player.play(AssetSource(audioPath));
  }

  Widget _buildQuestionBubble(ThemeProvider themeProvider) {
    final selectedCharacter = themeProvider.selectedCharacter;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 40, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black87, width: 3),
          ),
          child: const Text(
            "ออกเสียงถูกไหม ?",
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        Positioned(
          right: -14,
          top: -12,
          child: Transform.rotate(
            angle: 0.2,
            child: Image.asset(
              themeProvider.getCharacterHeadPath(selectedCharacter),
              width: 50,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                themeProvider.getDefaultCharacterHeadPath(selectedCharacter),
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, fallbackError, fallbackStackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerTile({
    required bool isCheck,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => onAnswer(isCheck: isCheck),
          child: Ink(
            height: 168,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 108)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                              Navigator.pushNamed(
                                context,
                                AppRouter.soundSettings,
                              );
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
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => playCurrentWord(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.yellow200,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: AppColors.yellow800,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuestionBubble(themeProvider),
                    const SizedBox(height: 70),
                    Image.asset(
                      question["image"]!,
                      height: 250,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: AppColors.gray75,
                          child: const Center(child: Text('Image not found')),
                        );
                      },
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildAnswerTile(
                          isCheck: true,
                          color: AppColors.success,
                          icon: Icons.check_rounded,
                        ),
                        const SizedBox(width: 12),
                        _buildAnswerTile(
                          isCheck: false,
                          color: AppColors.error,
                          icon: Icons.close_rounded,
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
