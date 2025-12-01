import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _fs = FirestoreService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final s = await _fs.fetchUserStats(uid);
    setState(() {
      _stats = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Summary', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  _statsSummary(),
                  const SizedBox(height: 20),
                  const Text('Recent Scores (mock simple chart)'),
                  const SizedBox(height: 8),
                  _simpleScoresChart(),
                ],
              ),
            ),
    );
  }

  Widget _statsSummary() {
    if (_stats == null) return const Text('No stats yet.');
    final quiz1 = _stats!['quiz1'] ?? {};
    final quiz2 = _stats!['quiz2'] ?? {};
    final lingsix = _stats!['lingsix'] ?? {};
    final totalPlayed = (quiz1['total_played'] ?? 0) + (quiz2['total_played'] ?? 0);
    final totalCorrect = (quiz1['total_correct'] ?? 0) + (quiz2['total_correct'] ?? 0);
    final accuracy = totalPlayed > 0 ? (totalCorrect / (totalPlayed * 12)) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total quizzes played: $totalPlayed'),
        Text('Total correct answers (approx): $totalCorrect'),
        Text('Overall accuracy: ${accuracy.toStringAsFixed(1)}%'),
        const SizedBox(height: 12),
        const Text('Per-sound accuracy:'),
        const SizedBox(height: 8),
        if (lingsix.isEmpty) const Text('No per-sound data yet.')
        else Column(
          children: (lingsix as Map<String, dynamic>).entries.map((e) {
            final correct = e.value['correct'] ?? 0;
            final total = e.value['total'] ?? 0;
            final acc = total > 0 ? (correct / total) * 100 : 0.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key),
                Text('${correct}/${total} (${acc.toStringAsFixed(1)}%)'),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _simpleScoresChart() {
    // For simplicity: read last 6 results and show as bars
    final recent = (_stats?['recent_scores'] as List<dynamic>?) ?? [];
    if (recent.isEmpty) return const Text('No recent scores');
    final maxScore = recent.map((r) => r['correct'] as int).fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: recent.map((r) {
          final correct = r['correct'] as int;
          final total = r['total'] as int;
          final barHeight = maxScore > 0 ? (correct / maxScore) * 100.0 + 10 : 20.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(height: barHeight, width: 18, color: Colors.indigo),
                const SizedBox(height: 6),
                Text('$correct/${total}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
