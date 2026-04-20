import 'dart:io';
import 'dart:convert';

void main() {
  final baseDir = Directory('assets/content/vocabulary');
  final Map<String, List<String>> result = {};

  for (var category in baseDir.listSync()) {
    if (category is Directory) {
      final categoryName = category.path.split('/').last;

      List<String> words = [];

      for (var word in category.listSync()) {
        if (word is Directory) {
          final wordName = word.path.split('/').last;
          words.add(wordName);
        }
      }

      result[categoryName] = words;
    }
  }

  final file = File('assets/data/vocabulary.json');
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
  // ignore: avoid_print
  print("✅ vocabulary.json generated!");
}