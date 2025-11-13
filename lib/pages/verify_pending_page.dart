import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class VerifyPendingPage extends StatefulWidget {
  const VerifyPendingPage({super.key});

  @override
  State<VerifyPendingPage> createState() => _VerifyPendingPageState();
}

class _VerifyPendingPageState extends State<VerifyPendingPage> {
  final _authService = AuthService();
  Timer? _timer;
  bool _isResending = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)?.settings.arguments as String?;
    _startCheckingVerification();
  }

  void _startCheckingVerification() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _authService.reloadUser(user);
      if (user.emailVerified) {
        _timer?.cancel();
        Navigator.pushReplacementNamed(context, '/verify-success');
      }
    });
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await _authService.resendVerification(user);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Verification email resent")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.mark_email_unread, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text("A verification link has been sent to:\n$_email",
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _isResending ? null : _resendEmail,
                child: Text(_isResending ? "Sending..." : "Resend Verification Email")),
            const SizedBox(height: 20),
            const Text(
              "Once verified, this page will automatically continue.",
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}
