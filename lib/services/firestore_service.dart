import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Get user by username
  Future<DocumentSnapshot?> getUserByUsername(String username) async {
    final snap = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  // Get user by UID 
  Future<DocumentSnapshot?> getUserByUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc : null;
  }

  // Add new user
  Future<void> addUser(String uid, String email, String username,
      {bool isGoogleSignIn = false}) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'password': null,
      'isGoogleSignIn': isGoogleSignIn,
    });
  }

  // Update existing user info
  Future<void> updateUser(String uid, {String? email, String? username}) async {
    final Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (username != null) data['username'] = username;

    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
  }
}
