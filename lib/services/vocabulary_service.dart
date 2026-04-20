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

    List<Map<String, String>> list = [];

    for (var word in data[category]) {
      list.add({
        "image": "assets/content/vocabulary/$category/$word/image.png",
        "sound": "assets/content/vocabulary/$category/$word/sound.mp3",
      });
    }

    return list;
  }

  static Future<List<String>> getCategories() async {
    final data = await loadRaw();
    return data.keys.toList();
  }
}