import 'package:flutter/material.dart';
import 'package:lingsix/app/theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Mock data - replace with actual data from your provider/service
  final int totalQuizzes = 1;
  final int totalCorrect = 2;
  final double overallAccuracy = 16.7;

  final Map<String, Map<String, dynamic>> perSoundAccuracy = const {
    'sh': {'correct': 0, 'total': 0, 'percent': 0.0},
    'ss': {'correct': 0, 'total': 0, 'percent': 0.0},
    'ah': {'correct': 0, 'total': 0, 'percent': 0.0},
    'ee': {'correct': 2, 'total': 12, 'percent': 16.7},
    'oo': {'correct': 0, 'total': 0, 'percent': 0.0},
    'mm': {'correct': 0, 'total': 0, 'percent': 0.0},
  };

  final List<Map<String, dynamic>> recentScores = const [
    {'correct': 2, 'total': 12},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/bg4.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.blue800),
                      iconSize: 40,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    const Text(
                      "ผลการทดสอบ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue800,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40), // Balance the back button
                  ],
                ),
              ),

              // Body content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      _buildSummaryCard(context),
                      const SizedBox(height: 24),

                      // Per-sound accuracy Card
                      _buildPerSoundCard(context),
                      const SizedBox(height: 24),

                      // Recent Scores Chart Card
                      _buildRecentScoresCard(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'สรุปผลการทดสอบ',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('จำนวนแบบทดสอบ:', '$totalQuizzes'),
          const SizedBox(height: 8),
          _buildSummaryRow('ตอบถูกทั้งหมด (ประมาณ):', '$totalCorrect'),
          const SizedBox(height: 8),
          _buildSummaryRow('ความแม่นยำรวม:', '${overallAccuracy.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPerSoundCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ความแม่นยำแต่ละเสียง:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 12),
          ...perSoundAccuracy.entries.map((entry) {
            final sound = entry.key;
            final data = entry.value;
            final correct = data['correct'] as int;
            final total = data['total'] as int;
            final percent = data['percent'] as double;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sound,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '$correct/$total (${percent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentScoresCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'คะแนนล่าสุด',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recentScores.asMap().entries.map((entry) {
                final data = entry.value;
                final correct = data['correct'] as int;
                final total = data['total'] as int;
                final percentage = total > 0 ? (correct / total) : 0.0;
                final barHeight = 120 * percentage;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 40,
                        height: barHeight.clamp(10, 120).toDouble(),
                        decoration: BoxDecoration(
                          color: AppColors.blue600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$correct/$total',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
