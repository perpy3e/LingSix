import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingsix/app/router.dart';
import 'package:lingsix/components/button/button.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class LessonsPage extends StatefulWidget {
  final String category;

  const LessonsPage({super.key, required this.category});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final AudioPlayer _player = AudioPlayer();

  List<Map<String, String>> vocabulary = [];
  int currentIndex = 0;
  bool isLoading = true;
  bool _hasAutoplayedFirst = false;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.stop);
    loadVocabulary();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> loadVocabulary() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/vocabulary.json',
    );

    final Map<String, dynamic> data = json.decode(jsonString);

    List<Map<String, String>> list = [];
    final categoryData = data[widget.category];

    if (categoryData is Map) {
      for (final entry in categoryData.entries) {
        final word = '${entry.key}';
        final displayWord = '${entry.value}';
        list.add({
          "word": word,
          "displayWord": displayWord,
          "image":
              "assets/content/vocabulary/${widget.category}/$word/image.png",
          "sound": "content/vocabulary/${widget.category}/$word/sound.mp3",
        });
      }
    } else if (categoryData is List) {
      // Backward compatibility with old array structure.
      for (final word in categoryData) {
        final romanized = '$word';
        list.add({
          "word": romanized,
          "displayWord": romanized,
          "image":
              "assets/content/vocabulary/${widget.category}/$romanized/image.png",
          "sound": "content/vocabulary/${widget.category}/$romanized/sound.mp3",
        });
      }
    }

    setState(() {
      vocabulary = list;
      isLoading = false;
    });

    if (mounted && !_hasAutoplayedFirst && list.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        playSound(list[0]["sound"]!);
        _hasAutoplayedFirst = true;
      });
    }
  }

  Future<void> playSound(String path) async {
    await _player.stop();
    await _player.play(AssetSource(path));
  }

  Widget _buildQuestionBubble(ThemeProvider themeProvider, String displayWord) {
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
          child: Text(
            'ออกเสียงตามนะว่า "$displayWord"',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
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

  void next() {
    if (currentIndex < vocabulary.length - 1) {
      setState(() => currentIndex++);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        playSound(vocabulary[currentIndex]["sound"]!);
      });
    }
  }

  void back() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        playSound(vocabulary[currentIndex]["sound"]!);
      });
    }
  }

  void resetToStart() {
    setState(() => currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      playSound(vocabulary[0]["sound"]!);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(themeProvider.getWallpaperPath('lesson')),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }

    if (vocabulary.isEmpty) {
      return Scaffold(
        body: Center(child: Text('No vocabulary found for ${widget.category}')),
      );
    }

    final item = vocabulary[currentIndex];
    final displayWord = item["displayWord"] ?? item["word"] ?? '';

    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(themeProvider.getWallpaperPath('lesson')),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 28,
                            color: AppColors.blue800,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          "บทเรียน",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.blue800),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            size: 28,
                            color: AppColors.blue800,
                          ),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRouter.soundSettings,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => playSound(item["sound"]!),
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
                        _buildQuestionBubble(themeProvider, displayWord),
                        const SizedBox(height: 24),
                        Image.asset(
                          item["image"]!,
                          height: 250,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 250,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text('Image not found'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Footer buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: currentIndex == vocabulary.length - 1
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(
                                flex: 1,
                                child: CustomButton(
                                  text: 'ย้อนกลับ',
                                  backgroundColor: Colors.white,
                                  onPressed: back,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                flex: 1,
                                child: CustomButton(
                                  text: 'เริ่มใหม่',
                                  onPressed: resetToStart,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(
                                flex: 1,
                                child: currentIndex > 0
                                    ? CustomButton(
                                        text: 'ย้อนกลับ',
                                        onPressed: back,
                                      )
                                    : const SizedBox(width: 80),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                flex: 1,
                                child: CustomButton(
                                  text: 'ถัดไป',
                                  onPressed: next,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
