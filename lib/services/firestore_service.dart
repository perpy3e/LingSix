import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ========== existing methods ==========
  // Get user by username
  Future<DocumentSnapshot?> getUserByUsername(String username) async {
    final snap = await _db.collection('users').where('username', isEqualTo: username).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<DocumentSnapshot?> getUserByUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc : null;
  }

  Future<void> addUser(String uid, String email, String username, {bool isGoogleSignIn = false}) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'password': null,
      'isGoogleSignIn': isGoogleSignIn,
    });
  }

  Future<void> updateUser(String uid, {String? email, String? username}) async {
    final Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (username != null) data['username'] = username;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
  }

  // ========== new functions for game analytics ==========
  /// Initialize stats documents for a newly registered user.
  Future<void> initUserStats(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final gameStatsRef = userRef.collection('game_stats').doc('summary');
    final lingsixRef = userRef.collection('lingsix_stats').doc('summary');
    final quizResultsRef = userRef.collection('quiz_results');

    final batch = _db.batch();
    batch.set(gameStatsRef, {
      'quiz1': {'last_played': null, 'total_played': 0, 'total_correct': 0},
      'quiz2': {'last_played': null, 'total_played': 0, 'total_correct': 0, 'cooldown_end': null},
    }, SetOptions(merge: true));

    // Initialize six sounds counters
    batch.set(lingsixRef, {
      'ee': {'correct': 0, 'total': 0},
      'oo': {'correct': 0, 'total': 0},
      'ss': {'correct': 0, 'total': 0},
      'sh': {'correct': 0, 'total': 0},
      'mm': {'correct': 0, 'total': 0},
      'ah': {'correct': 0, 'total': 0},
    }, SetOptions(merge: true));

    // add an empty recent_scores doc (optional)
    // No-op: quiz_results collection exists if needed when we write to it.

    await batch.commit();
  }

  /// Record a quiz result. `perSound` is an optional breakdown map `{soundKey: correctCount}`.
  Future<void> recordQuizResult(String uid, String quizId, int correct, int total, Map<String, int>? perSound) async {
    final userRef = _db.collection('users').doc(uid);
    final gameSummaryRef = userRef.collection('game_stats').doc('summary');
    final quizResultsRef = userRef.collection('quiz_results').doc();

    final now = Timestamp.now();
    final batch = _db.batch();

    // Add a result document
    batch.set(quizResultsRef, {
      'quiz_id': quizId,
      'date': now,
      'correct': correct,
      'total': total,
      'per_sound': perSound ?? {},
    });

    // Update summary counters
    final summarySnapshot = await gameSummaryRef.get();
    Map<String, dynamic> summary = {};
    if (summarySnapshot.exists) {
      summary = summarySnapshot.data() as Map<String, dynamic>;
    }

    final quizSummary = (summary[quizId] ?? {}) as Map<String, dynamic>;
    final existingPlayed = (quizSummary['total_played'] ?? 0) as int;
    final existingCorrect = (quizSummary['total_correct'] ?? 0) as int;

    quizSummary['total_played'] = existingPlayed + 1;
    quizSummary['total_correct'] = existingCorrect + correct;
    quizSummary['last_played'] = now;

    if (quizId == 'quiz2') {
      // Set cooldown_end to now + 24h
      final cooldownEnd = Timestamp.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch + Duration(hours: 24).inMilliseconds);
      quizSummary['cooldown_end'] = cooldownEnd;
    }

    // Merge into summary
    batch.set(gameSummaryRef, {quizId: quizSummary}, SetOptions(merge: true));

    // Update per-sound aggregation if provided
    if (perSound != null && perSound.isNotEmpty) {
      final lingsixRef = userRef.collection('lingsix_stats').doc('summary');
      final lingsnap = await lingsixRef.get();
      Map<String, dynamic> ldata = {};
      if (lingsnap.exists) ldata = lingsnap.data() as Map<String, dynamic>;
      perSound.forEach((sound, correctCount) {
        final old = (ldata[sound] ?? {'correct': 0, 'total': 0}) as Map<String, dynamic>;
        final oldCorrect = (old['correct'] ?? 0) as int;
        final oldTotal = (old['total'] ?? 0) as int;
        final newCorrect = oldCorrect + correctCount;
        final newTotal = oldTotal + total; // conservative: add total to each sound (adjust later)
        ldata[sound] = {'correct': newCorrect, 'total': newTotal};
      });
      batch.set(lingsixRef, ldata, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Check whether the user can play quiz (important for quiz2 cooldown).
  /// Returns an object with `canPlay: bool` and `availableAt: DateTime?`
  Future<_CanPlayResult> canPlayQuiz(String uid, String quizId) async {
    final gameSummaryRef = _db.collection('users').doc(uid).collection('game_stats').doc('summary');
    final snap = await gameSummaryRef.get();
    if (!snap.exists) return _CanPlayResult(canPlay: true, availableAt: null);
    final data = snap.data()!;
    final quiz = (data[quizId] ?? {}) as Map<String, dynamic>;
    final cooldown = quiz['cooldown_end'] as Timestamp?;
    if (cooldown == null) return _CanPlayResult(canPlay: true, availableAt: null);
    final availableAt = cooldown.toDate();
    final now = DateTime.now();
    if (now.isAfter(availableAt)) {
      return _CanPlayResult(canPlay: true, availableAt: null);
    } else {
      return _CanPlayResult(canPlay: false, availableAt: availableAt);
    }
  }

  /// Fetch aggregated user stats for dashboard (simple shape)
  Future<Map<String, dynamic>> fetchUserStats(String uid) async {
    final gameSummaryRef = _db.collection('users').doc(uid).collection('game_stats').doc('summary');
    final lingsixRef = _db.collection('users').doc(uid).collection('lingsix_stats').doc('summary');
    final resultsRef = _db.collection('users').doc(uid).collection('quiz_results').orderBy('date', descending: true).limit(6);

    final summarySnap = await gameSummaryRef.get();
    final lingsnap = await lingsixRef.get();
    final resultsSnap = await resultsRef.get();

    final summary = summarySnap.exists ? (summarySnap.data() as Map<String, dynamic>) : {};
    final lingsix = lingsnap.exists ? (lingsnap.data() as Map<String, dynamic>) : {};
    final recentScores = resultsSnap.docs.map((d) {
      final dd = d.data();
      return {
        'quizId': dd['quiz_id'],
        'date': dd['date'],
        'correct': dd['correct'],
        'total': dd['total'],
      };
    }).toList();

    return {'quiz1': summary['quiz1'] ?? {}, 'quiz2': summary['quiz2'] ?? {}, 'lingsix': lingsix, 'recent_scores': recentScores};
  }
}

class _CanPlayResult {
  final bool canPlay;
  final DateTime? availableAt;
  _CanPlayResult({required this.canPlay, required this.availableAt});
}
