import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ------------------------------
  // GET USER BY USERNAME
  // ------------------------------
  Future<DocumentSnapshot?> getUserByUsername(String username) async {
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  // ------------------------------
  // GET USER BY UID
  // ------------------------------
  Future<DocumentSnapshot?> getUserByUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc : null;
  }

  // ------------------------------
  // BASIC USER (LOGIN / GOOGLE)
  // ------------------------------
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

    'firstName': null,
    'lastName': null,
    'gender': null,
    'birthday': null,

    // gg
    'profileCompleted': false,

    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}


  // ------------------------------
  // FULL USER (SIGN UP)
  // ------------------------------
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
      'birthday': birthday != null ? Timestamp.fromDate(birthday) : null,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------
  // UPDATE USER
  // ------------------------------
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).update(data);
  }
}
