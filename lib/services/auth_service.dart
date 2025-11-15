import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  // ========= ERROR HANDLER =========
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use. Please log in or use another email to create an account.';
      case 'invalid-email':
        return 'The email address is invalid. Please check and try again.';
      case 'weak-password':
        return 'Your password is too weak. Try using a stronger password.';
      case 'user-not-found':
        return 'No account found with this email or username.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  // ========= LOGIN =========
  Future<User?> login(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername;

      // Username login
      if (!emailOrUsername.contains('@')) {
        final userDoc = await _firestore.getUserByUsername(emailOrUsername);

        if (userDoc == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with that username.',
          );
        }

        email = userDoc['email'];
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // ========= SIGN UP =========
  Future<User?> signUp(String email, String username, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create Firestore user entry
      await _firestore.addUser(
        cred.user!.uid,
        email,
        username,
        isGoogleSignIn: false,
      );

      // Send verification email
      await cred.user!.sendEmailVerification();

      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // ========= GOOGLE SIGN-IN =========
  Future<User?> signInWithGoogle({required String clientId}) async {
    throw UnimplementedError(
        "GoogleSignIn must be called from the UI page. Only pass the credential to AuthService.");
  }

  // ========= LOGOUT =========
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ========= PASSWORD RESET =========
  Future<void> sendPasswordReset(String emailOrUsername) async {
    try {
      String email = emailOrUsername;

      if (!emailOrUsername.contains('@')) {
        final userDoc = await _firestore.getUserByUsername(emailOrUsername);

        if (userDoc == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with that username.',
          );
        }

        email = userDoc['email'];
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // ========= RESEND VERIFICATION =========
  Future<void> resendVerification(User user) async {
    await user.sendEmailVerification();
  }

  // ========= RELOAD USER =========
  Future<User?> reloadUser(User user) async {
    await user.reload();
    return _auth.currentUser;
  }
}
