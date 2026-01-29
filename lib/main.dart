import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pages
import 'pages/auth_gate.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/verify_pending_page.dart';
import 'pages/verify_success_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/sound_settings_page.dart';
import 'pages/home_page.dart';
import 'pages/quiz_menu_page.dart';
import 'pages/quiz_page.dart';
import 'pages/quiz_summary_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LingSixApp());
}

class LingSixApp extends StatelessWidget {
  const LingSixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ling Six Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const AuthGate());

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignUpPage());

          case '/verify-pending':
            final user = settings.arguments as User?;
            if (user == null) throw Exception('User argument is required');
            return MaterialPageRoute(builder: (_) => VerifyPendingPage(user: user));

          case '/verify-success':
            return MaterialPageRoute(builder: (_) => const VerifySuccessPage());

          case '/forgot-password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

          case '/sound-settings':
            return MaterialPageRoute(builder: (_) => const SoundSettingsPage());

          case '/home':
            return MaterialPageRoute(builder: (_) => const HomePage());

          case '/quiz-menu':
            return MaterialPageRoute(builder: (_) => const QuizMenuPage());

          case '/quiz':
            final args = settings.arguments as Map<String, dynamic>?;
            final quizId = args?['quizId'] as String? ?? 'quiz1';
            return MaterialPageRoute(builder: (_) => QuizPage(quizId: quizId));

          case '/quiz-summary':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final monthlyResults = args['monthlyResults'] as Map<String, int>? ?? {
              'Jan': 80,
              'Feb': 90,
              'Mar': 75,
              'Apr': 60,
              'May': 85,
              'Jun': 70,
            }; // default demo data

            return MaterialPageRoute(
              builder: (_) => QuizSummaryPage(
                correct: args['correct'] as int? ?? 0,
                total: args['total'] as int? ?? 0,
                quizId: args['quizId'] as String? ?? 'quiz1',
                monthlyResults: monthlyResults,
              ),
            );

          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardPage());

          default:
            return null;
        }
      },
    );
  }
}
