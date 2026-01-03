import 'package:flutter/material.dart';
import 'app/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/auth/login_page.dart';
import 'pages/auth/sign_up_page.dart';
import 'pages/verify_pending_page.dart';
import 'pages/verify_success_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'package:lingsix/pages/home/home_page.dart';
import 'pages/settings/sound_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LingSix",
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.notoSansThaiLoopedTextTheme(
          AppTheme.lightTheme.textTheme,
        ),
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
        '/start-page': (_) => const StartPage(),
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
            Navigator.pushReplacementNamed(
              context,
              '/verify-pending',
              arguments: user.email,
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Verified user → main app
        return const StartPage();
      },
    );
  }
}
