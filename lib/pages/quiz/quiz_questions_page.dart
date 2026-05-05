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

  bool isAnswered = false;
  bool isFinishing = false;
  bool _hasAutoplayedFirst = false;

  final AudioPlayer _player = AudioPlayer();

  static const int questionsPerSet = 12;

  int questionIndex = 0;
  int score = 0;
  bool isLoading = true;

  Map<String, Map<String, int>> soundStats = {};

  final sounds = ["ah", "ee", "m", "oo", "s", "sh"];
  final random = Random();

  List<Map<String, String>> questions = [];

  List<String> _extractWords(dynamic categoryData) {
    if (categoryData is Map) {
      return categoryData.keys.map((key) => '$key').toList();
    }
    if (categoryData is List) {
      return categoryData.map((word) => '$word').toList();
    }
    return <String>[];
  }

  @override
  @override
  void initState() {
    super.initState();

    isAnswered = false; // ✅ reset
    isFinishing = false; // ✅ reset

    _player.setReleaseMode(ReleaseMode.stop);
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
      final words = _extractWords(data[sound]);
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

    if (mounted && !_hasAutoplayedFirst && generated.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        playCurrentWord();
        _hasAutoplayedFirst = true;
      });
    }
  }

  Future<void> onAnswer({required bool isCheck}) async {
    if (isAnswered || isFinishing) return; //block spam tab

    isAnswered = true;
    final question = questions[questionIndex];

    final sound = question["sound"]!;

    soundStats.putIfAbsent(sound, () => {"correct": 0, "total": 0});
    soundStats[sound]!["total"] = soundStats[sound]!["total"]! + 1;

    if (isCheck) {
      score++;
      soundStats[sound]!["correct"] = soundStats[sound]!["correct"]! + 1;
    }

    if (questionIndex < questionsPerSet - 1) {
      await Future.delayed(const Duration(milliseconds: 200)); //  smooth UX

      if (!mounted) return;

      setState(() {
        questionIndex++;
        isAnswered = false; // unlock next question
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        playCurrentWord();
      });
    } else {
      if (!mounted) return;
      setState(() => isFinishing = true);
      await finishQuiz();
    }
  }

  Future<void> finishQuiz() async {
    final accuracy = (score / questionsPerSet) * 100;

    final currentUser = user;
    if (currentUser == null) {
      if (mounted) {
        setState(() => isFinishing = false);
      }
      return;
    }

    //
    final themeProvider = context.read<ThemeProvider>();

    // ✅ 1. save quiz
    await firestoreService.saveQuizAttempt(
      uid: currentUser.uid,
      quizId: widget.quizId,
      score: score,
      totalQuestions: questionsPerSet,
      accuracy: accuracy,
      perSoundAccuracy: soundStats,
    );

    // ✅ 2.  from DB
    final summary = await firestoreService.getDashboardSummary(currentUser.uid);
    final testCount = summary['totalQuizzes'] ?? 0;

    // ✅ 3. sync theme
    await themeProvider.syncThemeStatusFromFirestore(currentUser.uid);

    // ✅ 4. show popup

    final shouldShowPopup = (testCount % 10 == 0 && testCount != 0);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          score: score,
          total: questionsPerSet,
          accuracy: accuracy,
          perSoundAccuracy: soundStats,
          showUnlockPopup: shouldShowPopup,
        ),
      ),
    );
  }

  /* fix code 24/04   
  Future<void> playCurrentWord() async {
    final audioPath = questions[questionIndex]["audio"]!;
    await _player.play(AssetSource(audioPath));
  }*/

  //add new
  Future<void> playCurrentWord() async {
    try {
      if (!mounted) return;

      final audioPath = questions[questionIndex]["audio"];

      if (audioPath == null || audioPath.isEmpty) return;

      await _player.stop(); // prevent overlap crash
      await _player.play(AssetSource(audioPath));
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }
  // end add new

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

  //buildAnswerTile
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
          onTap: (isAnswered || isFinishing)
              ? null
              : () => onAnswer(isCheck: isCheck),
          child: Ink(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              //fix from Icon(icon, color: Colors.white, size: 108),
              child: Icon(
                icon,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.12,
              ),
            ),
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
    if (isFinishing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังสรุปผลแบบทดสอบ...'),
            ],
          ),
        ),
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

                    //🔥🔥 new code expanded
                    Flexible(
                      flex: 3,
                      child: Center(
                        child: FractionallySizedBox(
                          heightFactor: 0.8,
                          child: Image.asset(
                            question["image"]!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.gray75,
                                child: const Center(
                                  child: Text('Image not found'),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ), // 👈 THIS COMMA WAS MISSING
                    //SizedBox(height: 70),
                    Expanded(
                      flex: 2,
                      child: Row(
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
                    ),
                  ],
                ),
              ),
            ),
          ); // ✅ closes Container properly
        },
      ),
    );
  }
}

void _showThemeUnlockedPopup(BuildContext context) {
  final themeProvider = context.read<ThemeProvider>();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ❌ CLOSE
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              /// 🎉 TITLE
              const Text(
                "ปลดล็อกธีมใหม่!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue800,
                ),
              ),

              const SizedBox(height: 16),

              /// 🐻 AVATAR
              Image.asset(
                themeProvider.getCharacterHeadPath(
                  themeProvider.selectedCharacter,
                ),
                height: 80,
              ),

              const SizedBox(height: 16),

              /// 💬 MESSAGE
              const Text(
                "เก่งมาก! ☀️🌊\nคุณทำแบบทดสอบครบ 10 ครั้งแล้ว\nปลดล็อกธีมใหม่แล้วนะ\nไปเที่ยวทะเลกันต่อเลย!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray700,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "ไปต่อเลย!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
