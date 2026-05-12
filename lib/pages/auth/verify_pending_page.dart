import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../components/button/button.dart';
import '../../utils/responsive.dart';

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
    final r = context.responsive;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/common/bg/login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.spacing(8),
                  vertical: r.spacing(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        size: r.icon(30),
                        color: AppColors.blue800,
                      ),
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
                    Expanded(
                      child: Text(
                        'ยืนยันอีเมล',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.blue800,
                        ),
                      ),
                    ),
                    SizedBox(width: r.spacing(48)),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final topSpacing = (constraints.maxHeight * 0.20).clamp(
                      110.0,
                      220.0,
                    );

                    return SingleChildScrollView(
                      padding: r.pagePadding(horizontal: 20),
                      child: ResponsiveContent(
                        maxWidth: r.contentMaxWidth(phone: 520, tablet: 640),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: topSpacing),
                              Image.asset(
                                'assets/common/illustrations/mail.png',
                                height: r.spacing(120).clamp(90, 170),
                              ),
                              SizedBox(height: r.spacing(32)),
                              Text(
                                'เราได้ส่งลิงก์ยืนยันไปที่:',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: r.text(22),
                                      color: AppColors.yellow800,
                                    ),
                              ),
                              SizedBox(height: r.spacing(10)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _email ?? '',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: r.text(22),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.yellow900,
                                      ),
                                ),
                              ),
                              SizedBox(height: r.spacing(24)),
                              CustomButton(
                                text: 'ส่งอีเมลยืนยันอีกครั้ง',
                                onPressed: _resendEmail,
                                isLoading: _isResending,
                              ),
                              SizedBox(height: r.spacing(22)),
                              Text(
                                'กำลังรอการยืนยัน...',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: r.text(20),
                                      color: AppColors.gray550,
                                    ),
                              ),
                              SizedBox(height: r.spacing(32)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
