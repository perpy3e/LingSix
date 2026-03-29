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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.blue800,
            ),

            onPressed: () => Navigator.pop(context),
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

          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
   return _card(

  child: Column(

    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          const Text(
            "ภาพรวม",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(

            height: 30,

            child: ElevatedButton.icon(

              onPressed: exportCSV,

              icon: const Icon(
                Icons.download,
                size: 16,
              ),

              label: const Text(
                "CSV",
                style: TextStyle(fontSize: 12),
              ),

              style: ElevatedButton.styleFrom(

                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),

      _stat("จำนวน Quiz", totalQuizzes.toString()),

      _stat("ตอบถูกทั้งหมด", totalCorrect.toString()),

      _stat(
        "Accuracy",
        "${overallAccuracy.toStringAsFixed(1)}%",
      ),
    ],
  ),
);

  }

  Widget _buildPerSoundCard() {
    final sounds = perSoundAccuracy.entries.toList();

    if (sounds.isEmpty) {
      return _card(child: const Center(child: Text("No sound accuracy data")));
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "ความแม่นยำแยกตามเสียง (%)",

            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Column(
            children: sounds.map((entry) {
              final sound = entry.key;

              final p = (entry.value['percent'] ?? 0).toDouble();

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [Text(sound), Text("${p.toStringAsFixed(1)}%")],
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 220,

            child: LineChart(
              LineChartData(
                minY: 0,

                maxY: 100,

                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,

                    spots: sounds.asMap().entries.map((e) {
                      final p = (e.value.value['percent'] ?? 0).toDouble();

                      return FlSpot(e.key.toDouble(), p.clamp(0, 100));
                    }).toList(),
                  ),
                ],

                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,

                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sounds.length) {
                          return const SizedBox();
                        }

                        return Text(sounds[value.toInt()].key);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              const Text(
                "Quiz Accuracy",

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              _buildMonthDropdown(),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(height: 220, child: _buildQuizBarChart()),

          const SizedBox(height: 20),

          _buildQuizList(),
        ],
      ),
    );
  }

  Widget _buildQuizBarChart() {
    return BarChart(
      BarChartData(
        minY: 0,

        maxY: 100,

        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,

              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index >= filteredScores.length) return const SizedBox();

                return Text("Quiz ${index + 1}");
              },
            ),
          ),
        ),

        barGroups: filteredScores.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,

            barRods: [
              BarChartRodData(
                toY: percent(e.value['correct'], e.value['total']),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuizList() {
    return Column(
      children: filteredScores.asMap().entries.map((entry) {
        final index = entry.key + 1;

        final score = entry.value;

        final p = percent(score['correct'], score['total']);

        return Card(
          child: ListTile(
            title: Text("Quiz $index"),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text("Score: ${score['correct']}/${score['total']}"),

                Text("Accuracy: ${p.toStringAsFixed(1)}%"),
              ],
            ),

            trailing: IconButton(
              icon: const Icon(Icons.more_vert),

              onPressed: () {
                _showQuizDetail(score, index);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  // month dropdown
  Widget _buildMonthDropdown() {
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
