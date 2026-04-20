import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class VerifySuccessPage extends StatefulWidget {
  const VerifySuccessPage({super.key});

  @override
  State<VerifySuccessPage> createState() => _VerifySuccessPageState();
}

class _VerifySuccessPageState extends State<VerifySuccessPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/common/bg/login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        size: 100,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "ยืนยันอีเมลสำเร็จ!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "อีเมลของคุณได้รับการยืนยันแล้ว",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gray550,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "กำลังกลับไปหน้าเข้าสู่ระบบ...",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray550,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
