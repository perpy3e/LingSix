import 'dart:convert';
import 'package:flutter/services.dart';

class VocabularyService {
  static Future<Map<String, dynamic>> loadRaw() async {
    final jsonString =
        await rootBundle.loadString('assets/data/vocabulary.json');
    return json.decode(jsonString);
  }

  static Future<List<Map<String, String>>> loadByCategory(
      String category) async {
    final data = await loadRaw();
    final categoryData = data[category];

    List<Map<String, String>> list = [];

    if (categoryData is Map) {
      for (final entry in categoryData.entries) {
        final word = '${entry.key}';
        final displayWord = '${entry.value}';
        list.add({
          "word": word,
          "displayWord": displayWord,
          "image": "assets/content/vocabulary/$category/$word/image.png",
          "sound": "assets/content/vocabulary/$category/$word/sound.mp3",
        });
      }
    } else if (categoryData is List) {
      for (final word in categoryData) {
        final romanized = '$word';
        list.add({
          "word": romanized,
          "displayWord": romanized,
          "image": "assets/content/vocabulary/$category/$romanized/image.png",
          "sound": "assets/content/vocabulary/$category/$romanized/sound.mp3",
        });
      }
    }

    return list;
  }

  static Future<List<String>> getCategories() async {
    final data = await loadRaw();
    return data.keys.where((key) => key != 'word_th').toList();
  }
}