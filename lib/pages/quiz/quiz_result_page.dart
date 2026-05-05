import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/router.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/providers/theme_provider.dart';

class QuizResultPage extends StatefulWidget {
  final int score;
  final int total;
  final double accuracy;
  final Map<String, Map<String, int>> perSoundAccuracy;
  final bool showUnlockPopup;

  const QuizResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.accuracy,
    required this.perSoundAccuracy,
    required this.showUnlockPopup,
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  @override
  void initState() {
    super.initState();

    if (widget.showUnlockPopup) {
      Future.microtask(() {
        _showThemeUnlockedPopup(context);
      });
    }
  }

  // ✅ FIX: dynamic theme text
  String _getThemeUnlockText(String theme) {
    switch (theme) {
      case 'summer':
        return "เก่งมาก! ☀️🌊\nคุณทำแบบทดสอบครบ 10 ครั้งแล้ว\nปลดล็อกธีมหน้าร้อนแล้วนะ\nไปเที่ยวทะเลกันต่อเลย!";

      case 'winter':
        return "สุดยอด! ❄️⛄\nคุณทำแบบทดสอบครบ 20 ครั้งแล้ว\nปลดล็อกธีมฤดูหนาวแล้ว\nไปเล่นหิมะกันเถอะ!";

      default:
        return "เก่งมาก!\nคุณปลดล็อกธีมใหม่แล้ว!";
    }
  }

  double _soundPercent(String sound) {
    final stat = widget.perSoundAccuracy[sound];
    if (stat == null) return 0;

    final totalCount = stat['total'] ?? 0;
    final correctCount = stat['correct'] ?? 0;

    if (totalCount == 0) return 0;
    return ((correctCount / totalCount) * 100).clamp(0, 100).toDouble();
  }

  String _feedbackText() {
    if (widget.score >= 11) return "เก่งมากเลย !";
    if (widget.score >= 9) return "ดีมาก !";
    if (widget.score >= 7) return "ทำได้ดีนะ !";
    if (widget.score >= 5) return "พยายามอีกนิด !";
    return "ลองใหม่นะ!";
  }

  Widget _buildFeedbackBubble(ThemeProvider themeProvider) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black87, width: 2.5),
          ),
          child: Text(
            _feedbackText(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.blue800,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const orderedSounds = ["ah", "ee", "m", "oo", "s", "sh"];

    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  themeProvider.getWallpaperPath('quiz'),
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "ผลการทดสอบ",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.blue800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 480),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue700.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(child: _buildFeedbackBubble(themeProvider)),

                                const SizedBox(height: 8),

                                // ✅ FIX: body follows selected character
                                Center(
                                  child: Image.asset(
                                    themeProvider.getCharacterBodyPath(
                                      themeProvider.selectedCharacter,
                                    ),
                                    height: 120,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        themeProvider.getDefaultCharacterBodyPath(
                                          themeProvider.selectedCharacter,
                                        ),
                                        height: 120,
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  "คะแนน ${widget.score}/${widget.total}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blue800,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "ความถูกต้อง ${widget.accuracy.toStringAsFixed(1)}%",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray700,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                ...orderedSounds.map((sound) {
                                  final percent = _soundPercent(sound);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            sound.toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            "${percent.toStringAsFixed(1)}%",
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔘 Dashboard
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRouter.dashboard,
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow200,
                          foregroundColor: AppColors.yellow700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Text(
                          "ภาพรวม",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔘 Home
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRouter.homePage,
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.yellow700,
                          side: const BorderSide(color: Colors.white, width: 2),
                          backgroundColor: AppColors.yellow200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "กลับสู่หน้าหลัก",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  // ✅ FULL FIX POPUP
  void _showThemeUnlockedPopup(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "ปลดล็อกธีมใหม่!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ FIX: head uses selected character
                Image.asset(
                  themeProvider.getCharacterHeadPath(
                    themeProvider.selectedCharacter,
                  ),
                  height: 80,
                ),

                const SizedBox(height: 16),

                // ✅ FIX: dynamic text (NO const)
                Text(
                  _getThemeUnlockText(themeProvider.currentTheme),
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.5),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("ไปต่อเลย!"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
