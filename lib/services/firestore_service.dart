import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =============================
  // USER SECTION
  // =============================

  Future<DocumentSnapshot?> getUserByUsername(String username) async {
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<DocumentSnapshot?> getUserByUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc : null;
  }

  Future<void> addUser(
    String uid,
    String email,
    String username, {
    bool isGoogleSignIn = false,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'isGoogleSignIn': isGoogleSignIn,
      'profileCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createUser({
    required String uid,
    required String email,
    required String username,
    required bool isGoogleSignIn,
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? birthday,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'isGoogleSignIn': isGoogleSignIn,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'birthday':
          birthday != null ? Timestamp.fromDate(birthday) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUser(
      String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).update(data);
  }

  // =============================
  // QUIZ SECTION
  // =============================

  Future<String> saveQuizAttempt({
    required String uid,
    required String quizId,
    required int score,
    required int totalQuestions,
    required double accuracy,
    required Map<String, dynamic> perSoundAccuracy,
  }) async {
    final ref = await _db
        .collection('users')
        .doc(uid)
        .collection('quiz_attempts')
        .add({
      'quizId': quizId,
      'score': score,
      'totalQuestions': totalQuestions,
      'accuracy': accuracy,
      'perSoundAccuracy': perSoundAccuracy,
      'playedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<List<QueryDocumentSnapshot>> getQuizAttempts(
      String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('quiz_attempts')
        .orderBy('playedAt', descending: true)
        .get();

    return snap.docs;
  }

  Future<DocumentSnapshot?> getLatestQuizAttempt(
      String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('quiz_attempts')
        .orderBy('playedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<bool> canPlayQuizToday(String uid) async {
    final latest = await getLatestQuizAttempt(uid);

    if (latest == null) return true;

    final data =
        latest.data() as Map<String, dynamic>;

    final Timestamp? ts = data['playedAt'];

    if (ts == null) return true;

    final playedDate = ts.toDate().toLocal();
    final now = DateTime.now().toLocal();

    return !(playedDate.year == now.year &&
        playedDate.month == now.month &&
        playedDate.day == now.day);
  }

  // =============================
  // DASHBOARD SUMMARY
  // =============================

  Future<Map<String, dynamic>> getDashboardSummary(
      String uid) async {
    final attempts = await getQuizAttempts(uid);

    int totalQuizzes = attempts.length;
    int totalCorrect = 0;
    int totalQuestions = 0;

    Map<String, Map<String, int>> soundStats = {};
    List<Map<String, dynamic>> recentScores = [];

    for (var doc in attempts) {
      final data =
          doc.data() as Map<String, dynamic>;

      final score = (data['score'] ?? 0) as int;
      final total =
          (data['totalQuestions'] ?? 0) as int;

      totalCorrect += score;
      totalQuestions += total;

      recentScores.add({
        'correct': score,
        'total': total,
      });

      final perSound =
          data['perSoundAccuracy']
              as Map<String, dynamic>?;

      if (perSound != null) {
        perSound.forEach((sound, value) {
          final correct =
              (value['correct'] ?? 0) as int;
          final total =
              (value['total'] ?? 0) as int;

          soundStats.putIfAbsent(sound,
              () => {'correct': 0, 'total': 0});

          soundStats[sound]!['correct'] =
              soundStats[sound]!['correct']! +
                  correct;

          soundStats[sound]!['total'] =
              soundStats[sound]!['total']! +
                  total;
        });
      }
    }

    Map<String, Map<String, dynamic>>
        perSoundAccuracy = {};

    soundStats.forEach((sound, stats) {
      final correct = stats['correct']!;
      final total = stats['total']!;
      final percent =
          total > 0 ? (correct / total) * 100 : 0.0;

      perSoundAccuracy[sound] = {
        'correct': correct,
        'total': total,
        'percent': percent,
      };
    });

    final overallAccuracy =
        totalQuestions > 0
            ? (totalCorrect / totalQuestions) *
                100
            : 0.0;

    return {
      'totalQuizzes': totalQuizzes,
      'totalCorrect': totalCorrect,
      'overallAccuracy': overallAccuracy,
      'perSoundAccuracy': perSoundAccuracy,
      'recentScores': recentScores.take(5).toList(),
    };
  }
}
