import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingsix/app/theme.dart';
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
import 'package:lingsix/utils/responsive.dart';

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

    final sorted = [...recentScores]
      ..sort((a, b) {
        final da = a['date'] as DateTime?;
        final db = b['date'] as DateTime?;
        return (da ?? DateTime(0)).compareTo(db ?? DateTime(0));
      });

    double safePercent(num? c, num? t) {
      if (c == null || t == null || t == 0) return 0;
      return ((c / t) * 100).clamp(0, 100).toDouble();
    }

    final firstAcc = safePercent(
      sorted.first['correct'],
      sorted.first['total'],
    );
    final lastAcc = safePercent(sorted.last['correct'], sorted.last['total']);
    final improvementRate = lastAcc - firstAcc;

    final accuracies = sorted
        .map((e) => safePercent(e['correct'], e['total']))
        .toList();

    final variance = calculateVariance(accuracies);
    final stdDev = calculateStdDev(accuracies);

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    /// ================= HEADER =================
    rows.add(["Listening Assessment Report"]);
    rows.add(["Generated At", now]);
    rows.add([]);

    /// ================= OVERVIEW =================
    rows.add(["=== Overview ==="]);
    rows.add(["Total Attempts", totalQuizzes]);
    rows.add(["Total Correct", totalCorrect]);
    rows.add(["Average Accuracy (%)", overallAccuracy.toStringAsFixed(2)]);
    rows.add([]);

    /// ================= PROGRESS =================
    rows.add(["=== Progress Analysis ==="]);
    rows.add(["Initial Score (%)", firstAcc.toStringAsFixed(2)]);
    rows.add(["Latest Score (%)", lastAcc.toStringAsFixed(2)]);
    rows.add(["Score Change (%)", improvementRate.toStringAsFixed(2)]);
    rows.add([]);

    /// ================= CONSISTENCY =================
    rows.add(["=== Consistency Analysis ==="]);
    rows.add(["Variance", variance.toStringAsFixed(2)]);
    rows.add(["Standard Deviation", stdDev.toStringAsFixed(2)]);

    String consistencyLevel;
    if (stdDev < 10) {
      consistencyLevel = "High consistency (stable performance)";
    } else if (stdDev < 20) {
      consistencyLevel = "Moderate variation (minor fluctuations)";
    } else {
      consistencyLevel = "High variation (inconsistent performance)";
    }

    rows.add(["Consistency Summary", consistencyLevel]);
    rows.add([]);

    rows.add([
      "Explanation",
      "Consistency is calculated from accuracy scores across all attempts. "
          "Lower values indicate stable and consistent performance, while higher values indicate variability.",
    ]);
    rows.add([]);

    /// ================= PHONEME =================
    rows.add(["=== Phoneme Analysis ==="]);
    rows.add(["Phoneme", "Accuracy (%)", "Level"]);

    List<Map<String, dynamic>> soundList = [];

    perSoundAccuracy.forEach((k, v) {
      final p = (v['percent'] ?? 0).toDouble().clamp(0, 100);
      soundList.add({"sound": k, "percent": p});
    });

    soundList.sort((a, b) => b["percent"].compareTo(a["percent"]));

    List<String> weak = [];

    for (var e in soundList) {
      final p = e["percent"];

      String level;
      if (p >= 80) {
        level = "High";
      } else if (p >= 60) {
        level = "Moderate";
      } else {
        level = "Low";
        weak.add(e["sound"]);
      }

      rows.add([e["sound"], p.toStringAsFixed(2), level]);
    }

    rows.add([]);

    final best = soundList.take(2).map((e) => e["sound"]).join(", ");

    rows.add(["Strong Phonemes", best]);
    rows.add(["Weak Phonemes", weak.isEmpty ? "-" : weak.join(", ")]);
    rows.add([]);

    /// ================= TREND =================
    rows.add(["=== Trend Data ==="]);
    rows.add(["Date", "Accuracy (%)"]);

    for (var score in sorted) {
      final date = score['date'] as DateTime?;
      final acc = safePercent(score['correct'], score['total']);

      rows.add([
        DateFormat('yyyy-MM-dd').format(date ?? DateTime.now()),
        acc.toStringAsFixed(2),
      ]);
    }

    rows.add([]);

    /// ================= NOTE =================
    rows.add([
      "Note",
      "This report is automatically generated for performance monitoring and analysis.",
    ]);

    /// SAVE
    final csv = const CsvEncoder().convert(rows);

    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/listening_report.csv";

    final file = File(path);
    await file.writeAsString(csv);

    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }
  // end CSV

  //🔥🔥🔥🔥🔥PDF -------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------
  Future<void> exportPDF() async {
    if (recentScores.isEmpty) return;

    final pdf = pw.Document();

    final regularFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Sarabun-Regular.ttf"),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Sarabun-Bold.ttf"),
    );

    final sorted = [...recentScores]
      ..sort((a, b) {
        final da = a['date'] as DateTime?;
        final db = b['date'] as DateTime?;
        return (da ?? DateTime(0)).compareTo(db ?? DateTime(0));
      });

    double safePercent(num? c, num? t) {
      if (c == null || t == null || t == 0) return 0;
      return ((c / t) * 100).clamp(0, 100).toDouble();
    }

    final firstAcc = safePercent(
      sorted.first['correct'],
      sorted.first['total'],
    );
    final lastAcc = safePercent(sorted.last['correct'], sorted.last['total']);

    final improvementRate = lastAcc - firstAcc;

    final accuracies = sorted
        .map((e) => safePercent(e['correct'], e['total']))
        .toList();

    final variance = calculateVariance(accuracies);
    final stdDev = calculateStdDev(accuracies);

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    /// ================= CHART =================
    pw.Widget buildTrendChart() {
      return pw.Column(
        children: [
          pw.SizedBox(height: 4),
          pw.Container(
            height: 140,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: accuracies.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;

                return pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        "${value.toStringAsFixed(0)}%",
                        style: pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 2),

                      pw.Container(
                        height: (value / 100) * 100,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 3),
                        color: PdfColors.blue,
                      ),

                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Test ${index + 1}",
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    /// ================= PAGE 1 =================
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) => [
          pw.Text(
            "Listening Report (รายงานการประเมินทักษะการฟัง)",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text("Generated: $now"),
          pw.Divider(),

          /// OVERVIEW
          pw.Text(
            "Overview (ภาพรวม)",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total Attempts (จำนวนแบบทดสอบ):"),
              pw.Text("$totalQuizzes"),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total Correct (จำนวนข้อที่ถูก):"),
              pw.Text("$totalCorrect"),
            ],
          ),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Average Accuracy (ความแม่นยำเฉลี่ย):"),
              pw.Text("${overallAccuracy.toStringAsFixed(1)}%"),
            ],
          ),

          pw.SizedBox(height: 10),

          pw.SizedBox(height: 16),

          /// TREND
          pw.Text(
            "Progress (พัฒนาการ)",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 2),
          buildTrendChart(),

          pw.SizedBox(height: 10),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Initial Test (ครั้งเริ่มต้น):"),
              pw.Text("${firstAcc.toStringAsFixed(1)}%"),
            ],
          ),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Latest Test (ครั้งล่าสุด):"),
              pw.Text("${lastAcc.toStringAsFixed(1)}%"),
            ],
          ),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Score Change (ความเปลี่ยนแปลง):"),
              pw.Text("${improvementRate.toStringAsFixed(1)}%"),
            ],
          ),

          pw.SizedBox(height: 16),

          /// CONSISTENCY
          pw.Text(
            "Consistency Analysis (ความสม่ำเสมอ)",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Variance (ความแปรปรวน):"),
              pw.Text(variance.toStringAsFixed(2)),
            ],
          ),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Standard Deviation (ส่วนเบี่ยงเบนมาตรฐาน):"),
              pw.Text(stdDev.toStringAsFixed(2)),
            ],
          ),

          pw.SizedBox(height: 10),

          ///
          pw.Text(
            "คำอธิบาย:\n"
            "ค่าความสม่ำเสมอนี้คำนวณจากคะแนนความแม่นยำ (%) ของแต่ละครั้ง เพื่อประเมินว่าผลลัพธ์มีความคงที่มากน้อยเพียงใด\n"
            "Variance (ความแปรปรวน) แสดงระดับการกระจายของคะแนนเมื่อเทียบกับค่าเฉลี่ย\n"
            "Standard Deviation (ส่วนเบี่ยงเบนมาตรฐาน) เป็นค่าที่ใช้บอกระดับความแปรปรวนในหน่วยเดียวกับคะแนน ทำให้สามารถตีความได้ชัดเจนมากขึ้น\n\n"
            "การแปลผล:\n"
            "ค่าต่ำ หมายถึง คะแนนมีความใกล้เคียงกันในแต่ละครั้ง แสดงถึงความสม่ำเสมอของผลลัพธ์\n"
            "ค่าสูง หมายถึง คะแนนมีความแตกต่างกันมากในแต่ละครั้ง แสดงถึงความไม่สม่ำเสมอของผลลัพธ์\n\n"
            "ตัวอย่าง:\n"
            "Standard Deviation ต่ำกว่า 10 แสดงถึงความสม่ำเสมอสูง\n"
            "ค่าระหว่าง 10 - 20 แสดงถึงความแปรปรวนเล็กน้อย\n"
            "ค่ามากกว่า 20 แสดงถึงความแปรปรวนสูง",
            style: pw.TextStyle(fontSize: 9),
          ),

          pw.SizedBox(height: 10),

          /// SUMMARY
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            color: stdDev < 10
                ? PdfColors.green100
                : stdDev < 20
                ? PdfColors.orange100
                : PdfColors.red100,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "สรุปความสม่ำเสมอ",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),

                pw.SizedBox(height: 6),

                pw.Text(
                  stdDev < 10
                      ? "คะแนนมีความเสถียรสูง (ทำได้ใกล้เคียงกันทุกครั้ง)"
                      : stdDev < 20
                      ? "คะแนนมีความแปรปรวนเล็กน้อย (มีขึ้นลงบ้าง)"
                      : "คะแนนมีความแปรปรวนสูง (ผลลัพธ์ไม่นิ่ง)",
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    List<Map<String, dynamic>> soundList = [];

    perSoundAccuracy.forEach((k, v) {
      final p = (v['percent'] ?? 0).toDouble().clamp(0, 100);
      soundList.add({"sound": k, "percent": p});
    });

    // sort มาก → น้อย
    soundList.sort((a, b) => b["percent"].compareTo(a["percent"]));

    // best = top 2
    final best = soundList.take(2).map((e) => e["sound"]).join(", ");

    // weak = < 60
    final weak = soundList
        .where((e) => e["percent"] < 60)
        .map((e) => e["sound"])
        .join(", ");

    /// ================= PAGE 2 =================
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) => [
          pw.Text(
            "Phoneme Analysis (การวิเคราะห์หน่วยเสียง)",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 12),

          pw.SizedBox(height: 12),

          /// BAR (FIXED 100%)
          pw.Column(
            children: soundList.map((e) {
              final p = (e["percent"] as double).round().clamp(0, 100);

              PdfColor color = p >= 80
                  ? PdfColors.green
                  : p >= 60
                  ? PdfColors.orange
                  : PdfColors.red;

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("${e["sound"]} ($p%)"),

                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: p == 0 ? 1 : p,
                          child: pw.Container(height: 10, color: color),
                        ),
                        pw.Expanded(
                          flex: (100 - p) == 0 ? 1 : (100 - p),
                          child: pw.Container(
                            height: 10,
                            color: PdfColors.grey300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          /// ANALYSIS (UPGRADED + BILINGUAL + EXPLAIN WHY)
          pw.Text(
            "Detailed Analysis (การวิเคราะห์เชิงลึก)",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          ...soundList.map((e) {
            final p = e["percent"] as double;

            String analysis;

            if (p >= 80) {
              analysis =
                  "High accuracy (ระดับสูง): ผู้ใช้สามารถแยกแยะเสียงนี้ได้อย่างแม่นยำและสม่ำเสมอ";
            } else if (p >= 60) {
              analysis =
                  "Moderate accuracy (ระดับปานกลาง): ทำได้ถูกในหลายครั้ง แต่ยังมีความคลาดเคลื่อน";
            } else {
              analysis = "Low accuracy (ระดับต่ำ): มีความผิดพลาดบ่อย";
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "${e["sound"]} : ${p.toStringAsFixed(1)}%",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(analysis, style: pw.TextStyle(fontSize: 11)),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 20),

          /// SUMMARY
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            color: PdfColors.green100,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Summary (สรุปผล)",
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.Text(
                  "Strong Phonemes - เสียงที่ทำได้ดี: $best",
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.Text(
                  "Weak Phonemes - เสียงที่ควรฝึกเพิ่ม: ${weak.isEmpty ? "-" : weak}",
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );

    final fileName = "Report_${DateFormat('ddMMMyyyy').format(DateTime.now())}";

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (format) async => pdf.save(),
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
    if (!mounted) return;

    //add theme
    // final themeProvider = context.read<ThemeProvider>();
    //await themeProvider.syncThemeStatusFromFirestore(user.uid);

    final themeProvider = context.read<ThemeProvider>();

    //  no await, no UI block
    Future.microtask(() {
      themeProvider.syncThemeStatusFromFirestore(user.uid);
    });

    // add 23/04‼️‼️
    recentScores = List<Map<String, dynamic>>.from(
      summary['recentScores'] ?? [],
    );
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

    perSoundAccuracy = Map<String, Map<String, dynamic>>.from(
      summary['perSoundAccuracy'] ?? {},
    );

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

    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
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

      return {'quizId': entry.key, 'accuracy': avg};
    }).toList();

    //  SORT quiz_1 → quiz_5
    aggregatedQuizScores.sort((a, b) {
      return a['quizId'].compareTo(b['quizId']);
    });
  }

  //‼️‼️‼️end add more function 24/04

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    if (isLoading) {
      return Scaffold(
        body: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            final selectedCharacter = themeProvider.selectedCharacter;
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    themeProvider.getWallpaperPath('dashboard'),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation(AppColors.blue600),
                      ),
                    ),
                    SizedBox(height: r.spacing(12)),
                    SizedBox(
                      height: r.spacing(180).clamp(120, 240),
                      child: Image.asset(
                        themeProvider.getCharacterBodyPath(selectedCharacter),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            themeProvider.getDefaultCharacterBodyPath(
                              selectedCharacter,
                            ),
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: r.spacing(16)),
                    Text(
                      'กำลังสรุปผลแบบทดสอบ...',
                      style: TextStyle(
                        fontSize: r.text(20),
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(themeProvider.getWallpaperPath('dashboard')),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: r.pagePadding(horizontal: 20, vertical: 16),
                      child: ResponsiveContent(
                        maxWidth: r.contentMaxWidth(phone: 560, tablet: 760),
                        child: Column(
                          children: [
                            _buildSummaryCard(),
                            SizedBox(height: r.spacing(20)),
                            _buildPerSoundCard(),
                            SizedBox(height: r.spacing(20)),
                            _buildQuizCard(),
                          ],
                        ),
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
    final r = context.responsive;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.spacing(24),
        vertical: r.spacing(16),
      ),

      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: r.icon(30),
              color: AppColors.blue800,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),

          Text(
            "ผลการทดสอบ",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.blue800),
          ),
          const Spacer(),
          SizedBox(width: r.spacing(48)),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
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
              Icon(
                Icons.info_outline_rounded,
                size: 48,
                color: AppColors.blue300,
              ),
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.blue800,
            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  drawVerticalLine: false,
                ),

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
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray550,
                          ),
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gray550,
                          ),
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

          if (filteredScores.isNotEmpty)
            SizedBox(height: 220, child: _buildQuizBarChart()),

          if (filteredScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 48,
                      color: AppColors.blue300,
                    ),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.blue800,
              ),
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
        gridData: FlGridData(
          show: true,
          horizontalInterval: 20,
          drawVerticalLine: false,
        ),

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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray550,
                  ),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray550,
                  ),
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
          final quizNumber =
              int.tryParse(quizId.toString().replaceAll('quiz_', '')) ?? 0;

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
    final sortedOldestFirst = [...filteredScores]
      ..sort((a, b) {
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
    final displayList = [...filteredScores]
      ..sort((a, b) {
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
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
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.blue600,
                ),
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

          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: AppColors.blue600,
          ),

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
    final correct = quiz['correct'] ?? 0;
    final total = quiz['total'] ?? 0;
    final accuracy = percent(correct, total);

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(102),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.blue100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue900.withAlpha(26),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.blue100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: AppColors.blue700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "รายละเอียดแบบทดสอบที่ $index",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.gray700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.blue10,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.blue100),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _detailMetric(
                            label: "คะแนน",
                            value: "$correct/$total",
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.blue100,
                        ),
                        Expanded(
                          child: _detailMetric(
                            label: "ความถูกต้อง",
                            value: "${accuracy.toStringAsFixed(1)}%",
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "ความถูกต้องของการออกเสียง",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.blue800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (soundResults.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.gray25,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        child: const Text(
                          "ยังไม่มีข้อมูลการออกเสียง",
                          style: TextStyle(color: AppColors.gray550),
                        ),
                      ),
                    ),
                  if (soundResults.isNotEmpty)
                    Column(
                      children: soundResults.entries.map((entry) {
                        final sound = entry.key;
                        final data = Map<String, dynamic>.from(entry.value);
                        final soundCorrect = data['correct'] ?? 0;
                        final soundTotal = data['total'] ?? 0;
                        final p = percent(soundCorrect, soundTotal);

                        Color percentColor = AppColors.error;
                        if (p >= 80) {
                          percentColor = AppColors.success;
                        } else if (p >= 60) {
                          percentColor = AppColors.yellow700;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gray25,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray100),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sound,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                  Text(
                                    "${p.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: percentColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: (p / 100).clamp(0, 1),
                                  minHeight: 6,
                                  backgroundColor: AppColors.gray100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    percentColor,
                                  ),
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
          ),
        );
      },
    );
  }

  Widget _detailMetric({
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray550,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.blue800,
          ),
        ),
      ],
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
