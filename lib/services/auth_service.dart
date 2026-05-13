import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  // ------------------------------
  // ERROR HANDLER
  // ------------------------------
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านไม่ปลอดภัย';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'network-request-failed':
        return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
      default:
        return e.message ?? 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
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
    String? gender,
    int? birthYear,
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
        authProvider: 'email',
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        birthYear: birthYear,
      );

      await cred.user!.sendEmailVerification();
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // ------------------------------
  // LOGOUT update clear cache 20/04
  // ------------------------------
Future<void> logout() async {
  await FirebaseAuth.instance.signOut();

  final googleSignIn = GoogleSignIn();

  try {
    await googleSignIn.disconnect(); 
  } catch (_) {}

  await googleSignIn.signOut();
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
  await user.reload();
  final refreshedUser = FirebaseAuth.instance.currentUser;

  if (refreshedUser != null && !refreshedUser.emailVerified) {
    await refreshedUser.sendEmailVerification();
  }
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

  // ------------------------------
  // DELETE ACCOUNT
  // ------------------------------
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("ไม่พบผู้ใช้งาน");
    }

    try {
      // Delete Firestore data first
      await _firestore.deleteUserData(user.uid);

      // Delete Firebase Authentication account
      await user.delete();

      // Logout
      await logout();
    } on FirebaseAuthException catch (e) {
      // Apple / Google / old login sessions
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'เพื่อความปลอดภัย กรุณาเข้าสู่ระบบใหม่ก่อนลบบัญชี',
        );
      }

      throw Exception(
        e.message ?? 'ไม่สามารถลบบัญชีได้',
      );
    } catch (e) {
      throw Exception(
        'เกิดข้อผิดพลาดในการลบบัญชี',
      );
    }
  }





} //end



