import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  // ------------------------------
  // ERROR HANDLER
  // ------------------------------
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
        return 'No user found.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Unknown error.';
    }
  }

  // ------------------------------
  // LOGIN
  // ------------------------------
  Future<User?> login(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername;

      if (!emailOrUsername.contains('@')) {
        final userDoc =
            await _firestore.getUserByUsername(emailOrUsername);
        if (userDoc == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Username not found',
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

  // ------------------------------
  // SIGN UP
  // ------------------------------
  Future<User?> signUp({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required DateTime birthday,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.createUser(
        uid: cred.user!.uid,
        email: email,
        username: username,
        isGoogleSignIn: false,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        birthday: birthday,
      );

      await cred.user!.sendEmailVerification();
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // ------------------------------
  // LOGOUT
  // ------------------------------
 Future<void> logout() async {
  await FirebaseAuth.instance.signOut();
}


  // ------------------------------
  // PASSWORD RESET
  // ------------------------------
  Future<void> sendPasswordReset(String emailOrUsername) async {
    try {
      String email = emailOrUsername;

      if (!emailOrUsername.contains('@')) {
        final userDoc =
            await _firestore.getUserByUsername(emailOrUsername);
        if (userDoc == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Username not found',
          );
        }
        email = userDoc['email'];
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // ------------------------------
  // RESEND VERIFICATION
  // ------------------------------
  Future<void> resendVerification(User user) async {
    await user.sendEmailVerification();
  }

  // ------------------------------
  // RELOAD USER
  // ------------------------------
  Future<User?> reloadUser(User user) async {
    await user.reload();
    return _auth.currentUser;
  }


  // ------------------------------
  // CLEAR TOKEN / LOGOUT
  // ------------------------------
 Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove only your app's auth-related keys
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');

    // Sign out from Firebase
    await _auth.signOut();
  }
}

