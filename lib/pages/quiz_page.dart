import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class QuizPage extends StatefulWidget {
  final String quizId;

  const QuizPage({super.key, required this.quizId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final FirestoreService _fs = FirestoreService();

  late String quizId;
  int currentIndex = 0;
  final int totalSections = 12;
  final Random _rnd = Random();
  bool _showingResult = false;
  bool _paused = false;
  Timer? _nextTimer;

  late List<_SectionData> sections;

  int correctCount = 0;
  int? selectedChoiceIndex;

  @override
  void initState() {
    super.initState();
    quizId = widget.quizId;
    _generateSections();
  }

  void _generateSections() {
    sections = List.generate(totalSections, (i) {
      final number = _rnd.nextInt(100) + 1;
      final imageUrl = 'https://picsum.photos/seed/${quizId}_$i/300/200';
      final correctChoice = _rnd.nextInt(1000);
      final choices = List<int>.generate(4, (j) => correctChoice + j + (j == 0 ? 0 : _rnd.nextInt(5)));
      final correctValue = choices[0];
      choices.shuffle(_rnd);
      final correctIdx = choices.indexOf(correctValue);
      return _SectionData(number: number, imageUrl: imageUrl, choices: choices, correctIndex: correctIdx);
    });
  }

  void _onChoiceTap(int idx) {
    if (_showingResult || _paused) return;
    setState(() {
      selectedChoiceIndex = idx;
      _showingResult = true;
      if (idx == sections[currentIndex].correctIndex) correctCount++;
    });
    _nextTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (currentIndex + 1 >= totalSections) {
        _finishQuiz();
      } else {
        setState(() {
          currentIndex++;
          selectedChoiceIndex = null;
          _showingResult = false;
        });
      }
    });
  }

  void _finishQuiz() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _fs.recordQuizResult(uid, quizId, correctCount, totalSections, {
        'ee': correctCount,
      });
    }
    Navigator.pushReplacementNamed(context, '/quiz-summary', arguments: {
      'correct': correctCount,
      'total': totalSections,
      'quizId': quizId,
    });
  }

  void _pauseOrResume() {
    setState(() => _paused = !_paused);
    if (_paused) _nextTimer?.cancel();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  Widget _buildChoice(int idx, int value) {
    final isSelected = selectedChoiceIndex == idx;
    Color? bg;
    if (_showingResult && isSelected) {
      bg = (idx == sections[currentIndex].correctIndex) ? Colors.green : Colors.red;
    } else if (_showingResult && !isSelected && idx == sections[currentIndex].correctIndex) {
      bg = Colors.green[200];
    }

    return GestureDetector(
      onTap: () => _onChoiceTap(idx),
      child: Container(
        width: 140,
        height: 100,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg ?? Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        alignment: Alignment.center,
        child: Text(
          value.toString(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = sections[currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: $quizId (${currentIndex + 1}/$totalSections)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _pauseOrResume,
            child: Text(_paused ? 'Resume' : 'Pause', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Section ${currentIndex + 1} / $totalSections', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Number: ${section.number}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Image.network(section.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 80)),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChoice(0, section.choices[0]),
                    _buildChoice(1, section.choices[1]),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChoice(2, section.choices[2]),
                    _buildChoice(3, section.choices[3]),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Correct so far: $correctCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionData {
  final int number;
  final String imageUrl;
  final List<int> choices;
  final int correctIndex;
  _SectionData({
    required this.number,
    required this.imageUrl,
    required this.choices,
    required this.correctIndex,
  });
}
