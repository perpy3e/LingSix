import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  //ADD CSV -------------------------
  Future<void> exportCSV() async {

  if (recentScores.isEmpty) return;

  List<List<dynamic>> rows = [];

  rows.add([
    "Quiz",
    "Correct",
    "Total",
    "Accuracy (%)",
    "Date"
  ]);

  for (int i = 0; i < recentScores.length; i++) {

    final score = recentScores[i];

    final correct = score['correct'] ?? 0;
    final total = score['total'] ?? 0;
    final date = score['date'];

    rows.add([
      "Quiz ${i+1}",
      correct,
      total,
      percent(correct, total).toStringAsFixed(1),
      date?.toString() ?? ""
    ]);
  }

  String csv = const ListToCsvConverter().convert(rows);

  final dir = await getTemporaryDirectory();

  final path = "${dir.path}/quiz_results.csv";

  final file = File(path);

  await file.writeAsString(csv);

  //  iOS
  final box = context.findRenderObject() as RenderBox?;

  await Share.shareXFiles(
    [XFile(path)],
    text: "Quiz Results CSV",
    sharePositionOrigin:
        box!.localToGlobal(Offset.zero) &
        box.size,
  );
}
//--------------------------------------------------------------------------------

  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = true;

  int totalQuizzes = 0;
  int totalCorrect = 0;
  double overallAccuracy = 0;

  Map<String, Map<String, dynamic>> perSoundAccuracy = {};

  List<Map<String, dynamic>> recentScores = [];

  List<Map<String, dynamic>> filteredScores = [];

  String selectedMonth = "ทั้งหมด";

  final List<String> months = const [
    "ทั้งหมด",
    "มกราคม",
    "กุมภาพันธ์",
    "มีนาคม",
    "เมษายน",
    "พฤษภาคม",
    "มิถุนายน",
    "กรกฎาคม",
    "สิงหาคม",
    "กันยายน",
    "ตุลาคม",
    "พฤศจิกายน",
    "ธันวาคม",
  ];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final summary = await _firestoreService.getDashboardSummary(user.uid);

    recentScores = List<Map<String, dynamic>>.from(
      summary['recentScores'] ?? [],
    );

    perSoundAccuracy = Map<String, Map<String, dynamic>>.from(
      summary['perSoundAccuracy'] ?? {},
    );

    totalQuizzes = summary['totalQuizzes'] ?? 0;

    totalCorrect = summary['totalCorrect'] ?? 0;

    overallAccuracy = (summary['overallAccuracy'] ?? 0).toDouble();

    applyMonthFilter();

    setState(() {
      isLoading = false;
    });
  }

  void applyMonthFilter() {
    if (selectedMonth == "ทั้งหมด") {
      filteredScores = recentScores;
      return;
    }

    final monthIndex = months.indexOf(selectedMonth);

    filteredScores = recentScores.where((score) {
      if (score['date'] == null) return false;

      final date = score['date'] as DateTime;

      return date.month == monthIndex;
    }).toList();
  }

  double percent(int correct, int total) {
    if (total == 0) return 0;

    final value = (correct / total) * 100;

    return value.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/bg4.png'),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),

                  child: Column(
                    children: [
                      _buildSummaryCard(),

                      const SizedBox(height: 20),

                      _buildPerSoundCard(),

                      const SizedBox(height: 20),

                      _buildQuizCard(),
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
                        if (value.toInt() >= sounds.length)
                          return const SizedBox();

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
      height: 36,

      padding: const EdgeInsets.symmetric(horizontal: 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade300),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,

          borderRadius: BorderRadius.circular(16),

          dropdownColor: Colors.white,

          elevation: 3,
          //menu max height
          menuMaxHeight: 250,

          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),

          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),

          items: months.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                child: Text(m),
              ),
            );
          }).toList(),

          onChanged: (value) {
            selectedMonth = value!;

            applyMonthFilter();

            setState(() {});
          },
        ),
      ),
    );
  }

  // quiz detail
  void _showQuizDetail(Map<String, dynamic> quiz, int index) {
    final soundResults = Map<String, dynamic>.from(quiz['soundResults'] ?? {});

    showDialog(
      context: context,

      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,

          child: Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /// HEADER
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Quiz $index Detail",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),

                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,

                          shape: BoxShape.circle,
                        ),

                        padding: const EdgeInsets.all(6),

                        child: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text("Score: ${quiz['correct']}/${quiz['total']}"),

                Text(
                  "Accuracy: ${percent(quiz['correct'], quiz['total']).toStringAsFixed(1)}%",
                ),

                const SizedBox(height: 16),

                const Text(
                  "Sound Accuracy",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                if (soundResults.isEmpty) const Text("No sound data"),

                if (soundResults.isNotEmpty)
                  Column(
                    children: soundResults.entries.map((entry) {
                      final sound = entry.key;

                      final data = Map<String, dynamic>.from(entry.value);

                      final correct = data['correct'] ?? 0;

                      final total = data['total'] ?? 0;

                      final p = percent(correct, total);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),

                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,

                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(sound),

                            Text(
                              "${p.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),

        borderRadius: BorderRadius.circular(16),
      ),

      child: child,
    );
  }

  Widget _stat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [Text(label), Text(value)],
    );
  }
}
