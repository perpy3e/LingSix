import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _firestore = FirestoreService();

  Future<void> _login() async {
    final emailOrUsername = _emailOrUsernameController.text.trim();
    final password = _passwordController.text.trim();
    try {
      final user = await _authService.login(emailOrUsername, password);

      if (user == null) return;

      if (!user.emailVerified) {
        await _authService.logout();
        Navigator.pushReplacementNamed(context, '/verify-pending',
            arguments: user.email);
        return;
      }

      Navigator.pushReplacementNamed(context, '/sound-settings');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // -------------------------------------------------------------
  //              GOOGLE SIGN-IN 
  // -------------------------------------------------------------
  Future<void> _googleLogin() async {
    try {
      const iosClientId =
          '406340157010-j7rukhv5mugeklnn09b2reduiovkl09k.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user cancel

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCred.user!;

      // --- SAVE TO FIRESTORE ---
      final userDoc = await _firestore.getUserByUid(user.uid);

      if (userDoc == null) {
        await _firestore.addUser(
          user.uid,
          user.email!,
          user.displayName ?? "",
          isGoogleSignIn: true,
        );
      }

      Navigator.pushReplacementNamed(context, '/sound-settings');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In failed: $e")));
    }
  }
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailOrUsernameController,
              decoration:
                  const InputDecoration(labelText: "Email or Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text("Login")),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            //                Google Sign-In button
            // -------------------------------------------------------------
            ElevatedButton.icon(
              onPressed: _googleLogin,
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            // -------------------------------------------------------------

            const SizedBox(height: 10),
            TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/forgot-password'),
                child: const Text("Forgot Password?")),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text("Don't have an account? Sign Up")),
          ],
        ),
      ),
    );
  }
}
