import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/router.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../components/button/button.dart';

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
  bool _timerStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_timerStarted) {
      _timerStarted = true;
      _email = ModalRoute.of(context)?.settings.arguments as String?;
      _startCheckingVerification();
    }
  }

  void _startCheckingVerification() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _authService.reloadUser(user);
      if (!mounted) return;
      if (user.emailVerified) {
        _timer?.cancel();
        Navigator.pushReplacementNamed(context, AppRouter.verifySuccess);
      }
    });
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await _authService.resendVerification(user);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, "Verification email resent");
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/bgLogin.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Back button
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.mark_email_unread,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Verify Your Email",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "A verification link has been sent to:",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _email ?? "",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: "Resend Verification Email",
                        onPressed: _resendEmail,
                        isLoading: _isResending,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Once verified, this page will automatically continue.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
