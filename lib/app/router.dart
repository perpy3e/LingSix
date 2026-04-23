import 'package:flutter/material.dart';

// Auth Pages
import 'package:lingsix/pages/auth/login_page.dart';
import 'package:lingsix/pages/auth/sign_up_page.dart';
import 'package:lingsix/pages/auth/forgot_password_page.dart';
import 'package:lingsix/pages/auth/infodata_page.dart';
import 'package:lingsix/pages/auth/verify_pending_page.dart';
import 'package:lingsix/pages/auth/verify_success_page.dart';

// Main Pages
import 'package:lingsix/pages/home/start_page.dart';
import 'package:lingsix/pages/home/home_page.dart';
import 'package:lingsix/pages/home/avatar_selected_page.dart';
import 'package:lingsix/pages/profile/profile_page.dart';
import 'package:lingsix/pages/settings/sound_settings_page.dart';

// Feature Pages
import 'package:lingsix/pages/lessons/lessons_page.dart';
import 'package:lingsix/pages/quiz/quiz_page.dart';
import 'package:lingsix/pages/dashboard/dashboard_page.dart';

class AppRouter {
  // Route Names (constants)
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyPending = '/verify-pending';
  static const String verifySuccess = '/verify-success';
  static const String forgotPassword = '/forgot-password';
  static const String infodata = '/infodata';
  
  static const String startPage = '/start-page';
  static const String avatarSelected = '/avatar-selected';
  static const String homePage = '/home-page';
  static const String profile = '/profile';
  static const String soundSettings = '/sound-settings';
  
  static const String lessons = '/lessons';
  static const String quiz = '/quiz';
  static const String dashboard = '/dashboard';

  // Route Map
  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginPage(),
    signup: (_) => const SignUpPage(),
    verifyPending: (_) => const VerifyPendingPage(),
    verifySuccess: (_) => const VerifySuccessPage(),
    forgotPassword: (_) => const ForgotPasswordPage(),
    infodata: (_) => InfoDataPage(),
    
    startPage: (_) => const StartPage(),
    avatarSelected: (_) => const AvatarSelectedPage(),
    homePage: (_) => const HomePage(),
    profile: (_) => ProfilePage(),
    soundSettings: (_) => const SoundSettingsPage(),
    
    lessons: (_) => const LessonsPage(category: "u"),
    quiz: (_) => const QuizPage(),
    dashboard: (_) => const DashboardPage(),
  };
}
