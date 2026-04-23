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

  @override
  void initState() {
    super.initState();
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

    if (data.containsKey(widget.category)) {
      for (var word in data[widget.category]) {
        list.add({
          "image":
              "assets/content/vocabulary/${widget.category}/$word/image.png",
          "sound":
              "content/vocabulary/${widget.category}/$word/sound.mp3",
        });
      }
    }

    setState(() {
      vocabulary = list;
      isLoading = false;
    });
  }

Future<void> playSound(String path) async {
  await _player.play(AssetSource(path)); 
}


  void next() {
    if (currentIndex < vocabulary.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void back() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  void resetToStart() {
    setState(() => currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vocabulary.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('No vocabulary found for ${widget.category}'),
        ),
      );
    }

    final item = vocabulary[currentIndex];

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
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.volume_up,
                              color: AppColors.yellow800,
                              size: 30,
                            ),
                          ),
                        ),
                        
                         const SizedBox(height: 20),
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
                        ? Center(
                            child: SizedBox(
                              width: 200,
                              child: CustomButton(
                                text: 'เริ่มใหม่อีกครั้ง',
                                onPressed: resetToStart,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(
                                flex: 1,
                                child: currentIndex > 0
                                    ? CustomButton(text: 'ย้อนกลับ', onPressed: back)
                                    : const SizedBox(width: 80),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                flex: 1,
                                child: CustomButton(text: 'ถัดไป', onPressed: next),
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
