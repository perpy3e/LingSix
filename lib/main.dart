import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingsix/providers/theme_provider.dart';

import 'pages/auth/login_page.dart';
import 'pages/home/start_page.dart';
import 'services/firestore_service.dart';
import 'pages/auth/infodata_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
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
          ...AppRouter.routes,
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _synced = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 🔹 Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // 🔹 Not logged in
        if (user == null) {
          return const LoginPage();
        }

        // 🔹 Not verified
        if (!user.emailVerified) {
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

        // 🔥 MAIN FIX
        return FutureBuilder(
          future: FirestoreService().getUserByUid(user.uid),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final doc = snapshot.data;
            final data = doc?.data() as Map<String, dynamic>?;
final authProvider = data?['authProvider'] ?? 'email';

final hasFirstName =
    data != null &&
    data['firstName'] != null &&
    data['firstName'].toString().trim().isNotEmpty;

final hasFullProfile =
    hasFirstName &&
    data['lastName'] != null &&
    data['lastName'].toString().trim().isNotEmpty;

//  Apple special condition
if (authProvider == 'apple') {

  if (!hasFirstName) {
    return const InfoDataPage();
  }

} else {

  if (!hasFullProfile) {
    return const InfoDataPage();
  }

}

            //
            if (!_synced) {
              _synced = true;

              Future.microtask(() {
                context.read<ThemeProvider>()
                    .syncThemeStatusFromFirestore(user.uid);
              });
            }

            return const StartPage();
          },
        );
      },
    );
  }
}