import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/pages/home/home_page.dart';
import 'package:lingsix/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

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

  final sorted = [...recentScores]..sort((a, b) {
    final da = a['date'] as DateTime?;
    final db = b['date'] as DateTime?;
    return (da ?? DateTime(0)).compareTo(db ?? DateTime(0));
  });

  final first = sorted.first;
  final last = sorted.last;

  final firstAcc = percent(first['correct'], first['total']);
  final lastAcc = percent(last['correct'], last['total']);

  final improvementRate = calculateImprovementRate(firstAcc, lastAcc);

  final accuracies = sorted.map((e) {
    return percent(e['correct'], e['total']);
  }).toList();

  final variance = calculateVariance(accuracies);
  final stdDev = calculateStdDev(accuracies);

  final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  /// =========================
  /// REPORT HEADER
  /// =========================
  rows.add(["Listening Skill Analytical Report"]);
  rows.add(["Generated At", now]);
  rows.add([]);

  /// =========================
  /// EXECUTIVE SUMMARY
  /// =========================
  rows.add(["=== Executive Summary ==="]);

  String performanceLevel = overallAccuracy >= 80
      ? "Excellent"
      : overallAccuracy >= 60
          ? "Moderate"
          : "Needs Improvement";

  rows.add(["Performance Level", performanceLevel]);
  rows.add(["Total Quiz Attempts", totalQuizzes]);
  rows.add(["Average Accuracy (%)", overallAccuracy.toStringAsFixed(2)]);
  rows.add([]);

  rows.add([
    "Description",
    "Accuracy reflects the overall listening and phoneme discrimination ability. Higher values indicate better performance."
  ]);
  rows.add([]);

  /// =========================
  /// PROGRESS ANALYSIS
  /// =========================
  rows.add(["=== Progress Analysis ==="]);

  rows.add(["Initial Accuracy (%)", firstAcc.toStringAsFixed(2)]);
  rows.add(["Latest Accuracy (%)", lastAcc.toStringAsFixed(2)]);
  rows.add(["Absolute Change (%)", (lastAcc - firstAcc).toStringAsFixed(2)]);
  rows.add(["Improvement Rate (%)", improvementRate.toStringAsFixed(2)]);

  String progressInterpretation;
  if (improvementRate > 20) {
    progressInterpretation = "Rapid improvement observed";
  } else if (improvementRate > 5) {
    progressInterpretation = "Steady improvement";
  } else if (improvementRate >= 0) {
    progressInterpretation = "Minimal or stable progress";
  } else {
    progressInterpretation = "Performance decline observed";
  }

  rows.add(["Interpretation", progressInterpretation]);
  rows.add([]);

  /// =========================
  /// CONSISTENCY ANALYSIS
  /// =========================
  rows.add(["=== Consistency Analysis ==="]);

  rows.add(["Variance", variance.toStringAsFixed(2)]);
  rows.add(["Standard Deviation", stdDev.toStringAsFixed(2)]);

  String consistencyLevel;
  if (stdDev < 10) {
    consistencyLevel = "Highly consistent performance";
  } else if (stdDev < 20) {
    consistencyLevel = "Moderate variability";
  } else {
    consistencyLevel = "High variability (inconsistent performance)";
  }

  rows.add(["Consistency Level", consistencyLevel]);
  rows.add([
    "Explanation",
    "Higher standard deviation indicates unstable performance across attempts."
  ]);
  rows.add([]);

  /// =========================
  /// SOUND ANALYSIS
  /// =========================
  rows.add(["=== Phoneme-Level Analysis ==="]);
  rows.add(["Phoneme", "Accuracy (%)", "Difficulty (%)", "Level"]);

  List<String> weakSounds = [];

  perSoundAccuracy.forEach((sound, data) {
    final p = (data['percent'] ?? 0).toDouble();
    final difficulty = 100 - p;

    String level;
    if (p >= 80) {
      level = "Strong";
    } else if (p >= 60) {
      level = "Moderate";
    } else {
      level = "Weak";
      weakSounds.add(sound);
    }

    rows.add([
      sound,
      p.toStringAsFixed(2),
      difficulty.toStringAsFixed(2),
      level
    ]);
  });

  rows.add([]);
  rows.add(["Phonemes Requiring Improvement", weakSounds.join(", ")]);
  rows.add([]);

  /// =========================
  /// TREND ANALYSIS
  /// =========================
  rows.add(["=== Trend Analysis ==="]);
  rows.add(["Date", "Accuracy (%)"]);

  for (var score in sorted) {
    final date = score['date'] as DateTime?;
    final acc = percent(score['correct'], score['total']);

    rows.add([
      DateFormat('yyyy-MM-dd').format(date ?? DateTime.now()),
      acc.toStringAsFixed(2),
    ]);
  }

  rows.add([]);

  /// =========================
  /// INSIGHTS
  /// =========================
  rows.add(["=== Key Insights ==="]);

  if (overallAccuracy >= 80) {
    rows.add(["User demonstrates high listening proficiency"]);
  } else if (overallAccuracy >= 60) {
    rows.add(["User has a solid foundation but can improve further"]);
  } else {
    rows.add(["User requires additional foundational training"]);
  }

  if (weakSounds.isNotEmpty) {
    rows.add(["Main weaknesses identified in phonemes: ${weakSounds.join(", ")}"]);
  }

  if (stdDev > 15) {
    rows.add(["Performance inconsistency detected; repetition is recommended"]);
  }

  rows.add([]);

 

  rows.add([]);

  rows.add([
    "Note",
    "This report is generated automatically to support learning analytics and performance evaluation."
  ]);

  /// SAVE
  final csv = const CsvEncoder().convert(rows);

  final dir = await getTemporaryDirectory();
  final path = "${dir.path}/listening_report.csv";

  final file = File(path);
  await file.writeAsString(csv);

  await Share.shareXFiles([XFile(path)]);
}
// end CSV
pw.Widget _row(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(value),
      ],
    ),
  );
}

//🔥🔥🔥🔥🔥function pdf
Future<void> exportPDF() async {
  if (recentScores.isEmpty) return;

  final pdf = pw.Document();

  /// SORT DATA
  final sorted = [...recentScores]..sort((a, b) {
    final da = a['date'] as DateTime?;
    final db = b['date'] as DateTime?;
    return (da ?? DateTime(0)).compareTo(db ?? DateTime(0));
  });

  final firstAcc = percent(sorted.first['correct'], sorted.first['total']);
  final lastAcc = percent(sorted.last['correct'], sorted.last['total']);

  final improvementRate = calculateImprovementRate(firstAcc, lastAcc);

  final accuracies =
      sorted.map((e) => percent(e['correct'], e['total'])).toList();

  final variance = calculateVariance(accuracies);
  final stdDev = calculateStdDev(accuracies);

  final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  /// 🔮 Forecast
  double slope = (lastAcc - firstAcc) / sorted.length;
  double predicted = (lastAcc + slope).clamp(0, 100);

  /// 🔁 Retake analysis
  Map<String, List<double>> quizMap = {};
  for (var s in recentScores) {
    final id = s['quizId'];
    final acc = percent(s['correct'], s['total']);

    quizMap.putIfAbsent(id, () => []);
    quizMap[id]!.add(acc);
  }

  List<String> improved = [];
  List<String> stagnant = [];

  quizMap.forEach((q, scores) {
    if (scores.length > 1) {
      if (scores.last > scores.first) {
        improved.add(q);
      } else {
        stagnant.add(q);
      }
    }
  });

  /// 🔍 Weak sounds
  List<String> weak = [];
  perSoundAccuracy.forEach((k, v) {
    final p = (v['percent'] ?? 0).toDouble();
    if (p < 60) weak.add(k);
  });

  /// 📊 SAFE BAR CHART (NO CANVAS)
  pw.Widget buildChart(List<double> data) {
    return pw.Container(
      height: 180,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: data.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;

          return pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    value.toStringAsFixed(0),
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Container(
                    height: (value / 100) * 140,
                    color: PdfColors.blue,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "T${index + 1}",
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        /// =========================
        /// HEADER
        /// =========================
        pw.Text(
          "Listening Performance Report",
          style: pw.TextStyle(
              fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text("Generated: $now"),
        pw.Divider(),

        /// =========================
        /// OVERVIEW
        /// =========================
        pw.Text("Overview",
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),

        pw.SizedBox(height: 8),

        _row("Total Attempts", totalQuizzes.toString()),
        _row("Total Correct", totalCorrect.toString()),
        _row("Average Accuracy",
            "${overallAccuracy.toStringAsFixed(1)}%"),

        pw.SizedBox(height: 16),

        /// =========================
        /// PROGRESS
        /// =========================
        pw.Text("Progress Analysis",
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),

        pw.SizedBox(height: 10),

        buildChart(accuracies),

        pw.SizedBox(height: 10),

        _row("Initial Accuracy", "${firstAcc.toStringAsFixed(1)}%"),
        _row("Latest Accuracy", "${lastAcc.toStringAsFixed(1)}%"),
        _row("Improvement Rate",
            "${improvementRate.toStringAsFixed(1)}%"),

        pw.SizedBox(height: 16),

        /// =========================
        /// CONSISTENCY
        /// =========================
        pw.Text("Consistency",
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),

        pw.SizedBox(height: 8),

        _row("Variance", variance.toStringAsFixed(2)),
        _row("Std Deviation", stdDev.toStringAsFixed(2)),

        pw.Text(
          stdDev < 10
              ? "Performance is stable"
              : stdDev < 20
                  ? "Moderate variability detected"
                  : "High inconsistency detected",
        ),

        pw.SizedBox(height: 16),

        /// =========================
        /// FORECAST
        /// =========================
        pw.Text("Prediction",
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),

        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          color: PdfColors.blue50,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Expected Next Accuracy"),
              pw.Text(
                "${predicted.toStringAsFixed(1)}%",
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        /// =========================
        /// RETAKE
        /// =========================
        pw.Text("Repetition Analysis",
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),

        pw.Text("Improved: ${improved.join(", ")}"),
        pw.Text("No improvement: ${stagnant.join(", ")}"),

        pw.SizedBox(height: 16),

        /// =========================
        /// SOUND ANALYSIS
        /// =========================
        pw.Text("Phoneme Accuracy",
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),

        pw.SizedBox(height: 10),

        ...perSoundAccuracy.entries.map((e) {
          final p = (e.value['percent'] ?? 0).toDouble();

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("${e.key}: ${p.toStringAsFixed(1)}%"),
              pw.Container(
                height: 6,
                width: p * 2,
                color: p > 80
                    ? PdfColors.green
                    : p > 60
                        ? PdfColors.orange
                        : PdfColors.red,
              ),
              pw.SizedBox(height: 6),
            ],
          );
        }).toList(),

        pw.SizedBox(height: 10),

        pw.Text(
          weak.isNotEmpty
              ? "Low accuracy phonemes: ${weak.join(", ")}"
              : "No significant phoneme weakness detected",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}
//🔥🔥🔥end function pdf


pw.Widget _sectionTitle(String text, pw.Font font) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}



String _performanceLevel(double acc) {
  if (acc >= 80) return "Excellent";
  if (acc >= 60) return "Moderate";
  return "Needs Improvement";
}

String _insightText(double acc, List<String> weak, double stdDev) {
  String text = "";

  if (acc >= 80) {
    text += "User demonstrates strong listening ability.\n";
  } else if (acc >= 60) {
    text += "User has moderate performance.\n";
  } else {
    text += "User needs improvement.\n";
  }

  if (weak.isNotEmpty) {
    text += "Weak phonemes: ${weak.join(", ")}\n";
  }

  if (stdDev > 15) {
    text += "Performance is inconsistent.\n";
  }

  return text;
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

// new add 24/04
  List<Map<String, dynamic>> aggregatedQuizScores = [];
//

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
    //add theme
    final themeProvider = context.read<ThemeProvider>();
  await themeProvider.syncThemeStatusFromFirestore(user.uid);

// add 23/04‼️‼️
    recentScores = List<Map<String, dynamic>>.from(summary['recentScores'] ?? []);
recentScores.sort((a, b) {
  final da = a['date'] as DateTime?;
  final db = b['date'] as DateTime?;
  return (db ?? DateTime(0)).compareTo(da ?? DateTime(0));
});


final seen = <String>{};
recentScores = recentScores.where((e) {
  final key = "${e['quizId']}_${e['date']}";
  if (seen.contains(key)) return false;
  seen.add(key);
  return true;
}).toList();
//end add ‼️‼️‼️

    perSoundAccuracy = Map<String, Map<String, dynamic>>.from(summary['perSoundAccuracy'] ?? {});

    totalQuizzes = summary['totalQuizzes'] ?? 0;

    totalCorrect = summary['totalCorrect'] ?? 0;

    overallAccuracy = (summary['overallAccuracy'] ?? 0).toDouble();

    applyMonthFilter();

    //add 24/04 aggregate quiz scores 
    buildAggregatedQuizScores();

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

  // =========================
// IMPROVEMENT RATE
// =========================
double calculateImprovementRate(double first, double last) {
  if (first == 0) return 0;
  return ((last - first) / first) * 100;
}

// =========================
// VARIANCE
// =========================
double calculateVariance(List<double> values) {
  if (values.isEmpty) return 0;

  final mean = values.reduce((a, b) => a + b) / values.length;

  final variance = values
      .map((v) => (v - mean) * (v - mean))
      .reduce((a, b) => a + b) /
      values.length;

  return variance;
}

// =========================
// STD DEV
// =========================
double calculateStdDev(List<double> values) {
  return sqrt(calculateVariance(values));
}

  //‼️‼️‼️add more function 24/04
  void buildAggregatedQuizScores() {
  Map<String, List<double>> quizMap = {};

  for (var score in recentScores) {
    final quizId = score['quizId'];
    final accuracy = (score['accuracy'] ?? 0).toDouble();

    quizMap.putIfAbsent(quizId, () => []);
    quizMap[quizId]!.add(accuracy);
  }

  aggregatedQuizScores = quizMap.entries.map((entry) {
    final list = entry.value;

    final avg = list.isNotEmpty
        ? list.reduce((a, b) => a + b) / list.length
        : 0.0;

    return {
      'quizId': entry.key,
      'accuracy': avg,
    };
  }).toList();

  //  SORT quiz_1 → quiz_5
  aggregatedQuizScores.sort((a, b) {
    return a['quizId'].compareTo(b['quizId']);
  });
}

//‼️‼️‼️end add more function 24/04

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

   return Scaffold(
  body: Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              themeProvider.getWallpaperPath('home'),
            ),
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
      ); //  Container
    },
  ), // Consumer
);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 28, color: AppColors.blue800),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HomePage()),
              );
            },
          ),
          const Spacer(),

          Text(
            "ผลการทดสอบ",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.blue800),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

//build summary card
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
                color: AppColors.blue800,
              ),
            ),

            Row(
  children: [
    FilledButton.icon(
      onPressed: exportCSV,
      icon: const Icon(Icons.download, size: 18),
      label: const Text("CSV"),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.yellow400,
        foregroundColor: AppColors.gray700,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),

    const SizedBox(width: 8),

    FilledButton.icon(
      onPressed: exportPDF,
      icon: const Icon(Icons.picture_as_pdf, size: 18),
      label: const Text("PDF"),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
  ],
)
          ],
        ),

        const SizedBox(height: 24),

        _stat("จำนวนแบบทดสอบ", totalQuizzes.toString()),
        const SizedBox(height: 12),

        _stat("จำนวนข้อที่ตอบถูก", totalCorrect.toString()),
        const SizedBox(height: 12),

        _stat("ความถูกต้อง (%)", "${overallAccuracy.toStringAsFixed(1)}%"),
      ],
    ),
  );
}
  //end build summary card

// ah ee ........
  Widget _buildPerSoundCard() {
    final orderedKeys = ["ah", "ee", "m", "oo", "s", "sh"];

final sounds = orderedKeys
    .where((key) => perSoundAccuracy.containsKey(key))
    .map((key) => MapEntry(key, perSoundAccuracy[key]!))
    .toList();

    if (sounds.isEmpty) {
      return _card(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.info_outline_rounded, size: 48, color: AppColors.blue300),
              const SizedBox(height: 12),
              const Text(
                "ยังไม่มีผลการทดสอบ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "ลองเริ่มทำดูนะ!",
                style: TextStyle(fontSize: 14, color: AppColors.gray550),
              ),
            ],
          ),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "ความถูกต้องของการออกเสียง (%)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blue800),
          ),

          const SizedBox(height: 20),

          Column(
            children: sounds.map((entry) {
              final sound = entry.key;
              final p = (entry.value['percent'] ?? 0).toDouble();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sound,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.blue100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${p.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.blue800,
                        ),
                      ),
                    ),
                  ],
                ),
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
                gridData: FlGridData(show: true, horizontalInterval: 20, drawVerticalLine: false),

                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.blue600,
                    barWidth: 3,
                    isStrokeCapRound: true,

                    spots: sounds.asMap().entries.map((e) {
                      final p = (e.value.value['percent'] ?? 0).toDouble();
                      return FlSpot(e.key.toDouble(), p.clamp(0, 100));
                    }).toList(),

                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.blue600,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],

                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,

                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sounds.length) {
                          return const SizedBox();
                        }

                        return Text(
                          sounds[value.toInt()].key,
                          style: const TextStyle(fontSize: 12, color: AppColors.gray550),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.gray550),
                        );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ความถูกต้อง",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue800,
                ),
              ),

              _buildMonthDropdown(),
            ],
          ),

          const SizedBox(height: 24),

          if (filteredScores.isNotEmpty) SizedBox(height: 220, child: _buildQuizBarChart()),

          if (filteredScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_outlined, size: 48, color: AppColors.blue300),
                    const SizedBox(height: 12),
                    const Text(
                      "ไม่มีข้อมูล",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "เลือกเดือนอื่น ๆ เพื่อดูข้อมูล",
                      style: TextStyle(fontSize: 13, color: AppColors.gray550),
                    ),
                  ],
                ),
              ),
            ),

          if (filteredScores.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              "รายละเอียด",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.blue800),
            ),
            const SizedBox(height: 12),
            _buildQuizList(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizBarChart() {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
     barTouchData: BarTouchData(
  enabled: false,
  handleBuiltInTouches: false, // doesn't work yet fix later
),
        gridData: FlGridData(show: true, horizontalInterval: 20, drawVerticalLine: false),

        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,

              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                //‼️oif (index < 0 || index > 4) return const SizedBox();
                 if (index < 0 || index >= aggregatedQuizScores.length) {
  return const SizedBox();
}


                return Text(
                  "Q${index + 1}",
                  style: const TextStyle(fontSize: 12, color: AppColors.gray550),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray550),
                );
              },
            ),
          ),
        ),
/*‼️old code fix 24/04: barGroups: filteredScores.asMap().entries.map((e) {
          final accuracy = percent(e.value['correct'], e.value['total']);
        */
        barGroups: aggregatedQuizScores.map((e) {
  final accuracy = (e['accuracy'] ?? 0).toDouble();

  final quizId = e['quizId'] ?? '';
  final quizNumber = int.tryParse(
    quizId.toString().replaceAll('quiz_', ''),
  ) ?? 0;

  return BarChartGroupData(
    x: quizNumber - 1, // ✅ REAL POSITION (0–4)

            barRods: [
              BarChartRodData(
                toY: accuracy,
                color: AppColors.blue600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

//buildQuizList()

  Widget _buildQuizList() {
  // sort old-new 
  final sortedOldestFirst = [...filteredScores]..sort((a, b) {
    final da = a['date'] as DateTime?;
    final db = b['date'] as DateTime?;
    return (da ?? DateTime(0)).compareTo(db ?? DateTime(0));
  });

  // count attempts
  Map<String, int> attemptCounter = {};
  Map<Map<String, dynamic>, int> attemptMap = {};

  for (var score in sortedOldestFirst) {
    final quizId = score['quizId'] ?? '';
    attemptCounter[quizId] = (attemptCounter[quizId] ?? 0) + 1;
    attemptMap[score] = attemptCounter[quizId]!;
  }

  //show LATEST first 
  final displayList = [...filteredScores]..sort((a, b) {
    final da = a['date'] as DateTime?;
    final db = b['date'] as DateTime?;
    return (db ?? DateTime(0)).compareTo(da ?? DateTime(0)); // newest first
  });

  return Column(
    children: displayList.asMap().entries.map((entry) {
      final score = entry.value;

      final quizId = score['quizId'] ?? '';
      final quizNumber = quizId.toString().replaceAll('quiz_', '');

      final attempt = attemptMap[score] ?? 1;

      final p = percent(score['correct'], score['total']);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blue10,
          border: const Border(
            left: BorderSide(color: AppColors.blue600, width: 4),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "แบบทดสอบที่ $quizNumber",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray700,
                          ),
                        ),

                        if (attempt > 1)
                          TextSpan(
                            text: " (ทำซ้ำครั้งที่ $attempt)",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.blue100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${score['correct']}/${score['total']}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue800,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "ถูกต้อง ${p.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray550,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  if (score['date'] != null)
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(score['date']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gray550,
                      ),
                    ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.blue600),
              onPressed: () {
                final index = entry.key + 1;
                _showQuizDetail(score, index);
              },
            ),
          ],
        ),
      );
    }).toList(),
  );
}
  // end buildQuizList()


  Widget _buildMonthDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue300, width: 1.5),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          elevation: 4,
          menuMaxHeight: 250,

          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AppColors.blue600),

          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),

          items: months.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                  color: Colors.black.withValues(alpha: 0.2),
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
                        "รายละเอียดแบบทดสอบที่ $index",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                Text("คะแนน: ${quiz['correct']}/${quiz['total']}"),

                Text("ความถูกต้อง: ${percent(quiz['correct'], quiz['total']).toStringAsFixed(1)}%"),

                const SizedBox(height: 16),

                const Text("ความถูกต้องของการออกเสียง", style: TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                if (soundResults.isEmpty) const Text("ยังไม่มีข้อมูลการออกเสียง"),

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

                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),

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
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.gray550,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.blue800,
          ),
        ),
      ],
    );
  }
}
