import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/start_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasData) {
          return const StartPage();
        }
        return const LoginPage();
      },
    );
  }
}
