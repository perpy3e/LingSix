import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  // Login with email or username
  Future<User?> login(String emailOrUsername, String password) async {
    String email = emailOrUsername;

    // Check if username
    if (!emailOrUsername.contains('@')) {
      final userDoc = await _firestore.getUserByUsername(emailOrUsername);
      if (userDoc == null) {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'No user found with that username');
      }
      email = userDoc['email'];
    }

    final cred =
        await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  // Sign up with email + username + password
  Future<User?> signUp(String email, String username, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await _firestore.addUser(cred.user!.uid, email, username);
    await cred.user!.sendEmailVerification();
    return cred.user;
  }

  // Google Sign-In
  Future<User?> signInWithGoogle(
      {required String clientId}) async {
    // GoogleSignIn moved to page
    throw UnimplementedError(
        "Call GoogleSignIn directly from page to get credential");
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Send password reset
  Future<void> sendPasswordReset(String emailOrUsername) async {
    String email = emailOrUsername;

    if (!emailOrUsername.contains('@')) {
      final userDoc = await _firestore.getUserByUsername(emailOrUsername);
      if (userDoc == null) {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'No user found with that username');
      }
      email = userDoc['email'];
    }

    await _auth.sendPasswordResetEmail(email: email);
  }

  // Resend verification email
  Future<void> resendVerification(User user) async {
    await user.sendEmailVerification();
  }

  // Reload user
  Future<User?> reloadUser(User user) async {
    await user.reload();
    return _auth.currentUser;
  }
}
