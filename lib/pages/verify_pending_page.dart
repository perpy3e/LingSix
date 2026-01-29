import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'verify_success_page.dart';

class VerifyPendingPage extends StatefulWidget {
  final User user;

  const VerifyPendingPage({super.key, required this.user});

  @override
  State<VerifyPendingPage> createState() => _VerifyPendingPageState();
}

class _VerifyPendingPageState extends State<VerifyPendingPage> {
  final _authService = AuthService();
  Timer? _timer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCheckingVerification();
  }

  void _startCheckingVerification() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _authService.reloadUser(user);
      if (user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerifySuccessPage()),
          );
        }
      }
    });
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await _authService.resendVerification(widget.user);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Verification email resent")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
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
      appBar: AppBar(
        title: const Text("Verify Pending"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "A verification email has been sent. Please check your inbox.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _isResending
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resendEmail,
                    child: const Text("Resend Email"),
                  ),
          ],
        ),
      ),
    );
  }
}
