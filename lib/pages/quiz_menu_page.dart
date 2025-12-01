import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizMenuPage extends StatefulWidget {
  const QuizMenuPage({super.key});

  @override
  State<QuizMenuPage> createState() => _QuizMenuPageState();
}

class _QuizMenuPageState extends State<QuizMenuPage> {
  final FirestoreService _fs = FirestoreService();
  bool _quiz2Locked = false;
  DateTime? _quiz2AvailableAt;

  @override
  void initState() {
    super.initState();
    _checkQuiz2Cooldown();
  }

  Future<void> _checkQuiz2Cooldown() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final res = await _fs.canPlayQuiz(uid, 'quiz2');
    setState(() {
      _quiz2Locked = !res.canPlay;
      _quiz2AvailableAt = res.availableAt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableText = _quiz2AvailableAt != null
        ? 'Available at: ${_quiz2AvailableAt!.toLocal()}'
        : 'Locked';

    return Scaffold(
      appBar: AppBar(title: const Text('Select Quiz'), leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/quiz', arguments: {'quizId': 'quiz1'}),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Quiz 1 (Practice)', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _quiz2Locked
                  ? null
                  : () => Navigator.pushNamed(context, '/quiz', arguments: {'quizId': 'quiz2'}),
              style: ElevatedButton.styleFrom(
                backgroundColor: _quiz2Locked ? Colors.grey : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Quiz 2 (Daily Challenge)', style: TextStyle(fontSize: 18)),
                    if (_quiz2Locked) const SizedBox(height: 8),
                    if (_quiz2Locked) Text(availableText, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _checkQuiz2Cooldown,
                child: const Text('Refresh Quiz Availability')),
          ],
        ),
      ),
    );
  }
}
