import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingsix/app/router.dart';
import 'package:lingsix/components/button/button.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lingsix/utils/responsive.dart';

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

  Widget _buildQuestionBubble(
    BuildContext context,
    ThemeProvider themeProvider,
    String displayWord,
  ) {
    final r = context.responsive;
    final selectedCharacter = themeProvider.selectedCharacter;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            r.spacing(24),
            r.spacing(20),
            r.spacing(40),
            r.spacing(20),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r.spacing(28)),
            border: Border.all(color: Colors.black87, width: r.spacing(3)),
          ),
          child: Text(
            'ออกเสียงตามนะว่า "$displayWord"',
            style: TextStyle(fontSize: r.text(28), fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        Positioned(
          right: -r.spacing(14),
          top: -r.spacing(12),
          child: Transform.rotate(
            angle: 0.2,
            child: Image.asset(
              themeProvider.getCharacterHeadPath(selectedCharacter),
              width: r.spacing(50),
              height: r.spacing(50),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                themeProvider.getDefaultCharacterHeadPath(selectedCharacter),
                width: r.spacing(50),
                height: r.spacing(50),
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
    final r = context.responsive;

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
                    padding: EdgeInsets.symmetric(
                      horizontal: r.spacing(24),
                      vertical: r.spacing(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            size: r.icon(30),
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
                          icon: Icon(
                            Icons.settings,
                            size: r.icon(28),
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
                            padding: EdgeInsets.all(r.spacing(16)),
                            decoration: BoxDecoration(
                              color: AppColors.yellow200,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: r.spacing(2),
                              ),
                            ),
                            child: Icon(
                              Icons.volume_up,
                              color: AppColors.yellow800,
                              size: r.icon(30),
                            ),
                          ),
                        ),

                        SizedBox(height: r.spacing(16)),
                        _buildQuestionBubble(
                          context,
                          themeProvider,
                          displayWord,
                        ),
                        SizedBox(height: r.spacing(24)),
                        Image.asset(
                          item["image"]!,
                          height: r.spacing(250).clamp(180, 320),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: r.spacing(250).clamp(180, 320),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: r.spacing(24),
                      vertical: r.spacing(20),
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
                              SizedBox(width: r.spacing(16)),
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
                              SizedBox(width: r.spacing(16)),
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
