import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/services/firestore_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _firestoreService =
      FirestoreService();

  bool isLoading = true;

  int totalQuizzes = 0;
  int totalCorrect = 0;
  double overallAccuracy = 0;

  Map<String, Map<String, dynamic>>
      perSoundAccuracy = {};

  List<Map<String, dynamic>> recentScores = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final summary =
        await _firestoreService
            .getDashboardSummary(user.uid);

    setState(() {
      totalQuizzes =
          summary['totalQuizzes'] ?? 0;

      totalCorrect =
          summary['totalCorrect'] ?? 0;

      overallAccuracy =
          (summary['overallAccuracy'] ?? 0)
              .toDouble();

      perSoundAccuracy =
          Map<String, Map<String, dynamic>>
              .from(summary[
                  'perSoundAccuracy'] ??
                  {});

      recentScores =
          List<Map<String, dynamic>>.from(
              summary['recentScores'] ??
                  []);

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/img/bg4.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                          24),
                  child: Column(
                    children: [
                      _buildSummaryCard(),

                      const SizedBox(
                          height: 20),

                      _buildPerSoundCard(),

                      const SizedBox(
                          height: 20),

                      _buildRecentScoresCard(),

                      const SizedBox(
                          height: 20),
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

  // ==========================
  // HEADER
  // ==========================

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              color: AppColors.blue800,
            ),
            iconSize: 32,
            onPressed: () =>
                Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            "ผลการทดสอบ",
            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.blue800,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  // ==========================
  // SUMMARY CARD
  // ==========================

  Widget _buildSummaryCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Colors.white.withAlpha(
                235),
        borderRadius:
            BorderRadius.circular(
                16),
      ),
      child: Column(
        children: [
          const Text(
            "ภาพรวม",
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _buildStatRow(
              "จำนวน Quiz",
              totalQuizzes
                  .toString()),

          _buildStatRow(
              "ตอบถูกทั้งหมด",
              totalCorrect
                  .toString()),

          _buildStatRow(
            "Accuracy",
            "${overallAccuracy.toStringAsFixed(1)}%",
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      String label,
      String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
              vertical: 6),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================
  // PER SOUND CARD
  // ==========================

  Widget _buildPerSoundCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Colors.white.withAlpha(
                235),
        borderRadius:
            BorderRadius.circular(
                16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "LingSix Sound Accuracy",
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (perSoundAccuracy
              .isEmpty)
            const Text(
                "ยังไม่มีข้อมูล"),

          ...perSoundAccuracy
              .entries
              .map((entry) {
            final sound =
                entry.key;

            final data =
                entry.value;

            final percent =
                (data['percent']
                        as num)
                    .toDouble();

            return Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                          vertical:
                              6),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Text(sound),

                  Text(
                    "${percent.toStringAsFixed(1)}%",
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
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

  // ==========================
  // RECENT SCORES CARD
  // ==========================

  Widget _buildRecentScoresCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Colors.white.withAlpha(
                235),
        borderRadius:
            BorderRadius.circular(
                16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Quiz ล่าสุด",
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (recentScores
              .isEmpty)
            const Text(
                "ยังไม่มีการทำ Quiz"),

          ...recentScores.map(
              (scoreData) {
            final correct =
                scoreData[
                        'correct']
                    as int;

            final total =
                scoreData[
                        'total']
                    as int;

            final percent =
                (correct /
                        total) *
                    100;

            return Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                          vertical:
                              6),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Text(
                      "$correct / $total"),

                  Text(
                    "${percent.toStringAsFixed(1)}%",
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
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
}
