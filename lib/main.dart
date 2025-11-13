import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/verify_pending_page.dart';
import 'pages/verify_success_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/sound_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DbToneApp());
}

class DbToneApp extends StatelessWidget {
  const DbToneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ling Six Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignUpPage(),
        '/verify-pending': (_) => const VerifyPendingPage(),
        '/verify-success': (_) => const VerifySuccessPage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/sound-settings': (_) => const SoundSettingsPage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Splash/loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // Not logged in
          return const LoginPage();
        }

        // User logged in but not verified
        if (!user.emailVerified) {
          // Redirect to verify pending page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/verify-pending',
                arguments: user.email);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Verified user → main app
        return const SoundSettingsPage();
      },
    );
  }
}
