import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../utils/responsive.dart';

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
          child: Center(
            child: SingleChildScrollView(
              padding: r.pagePadding(horizontal: 20),
              child: ResponsiveContent(
                maxWidth: r.contentMaxWidth(phone: 460, tablet: 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: r.spacing(80),
                          height: r.spacing(80),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          size: r.icon(100),
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    SizedBox(height: r.spacing(20)),
                    Text(
                      "ยืนยันอีเมลสำเร็จ!",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: r.spacing(10)),
                    Text(
                      "อีเมลของคุณได้รับการยืนยันแล้ว",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: r.spacing(24)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: r.spacing(16),
                          height: r.spacing(16),
                          child: CircularProgressIndicator(
                            strokeWidth: r.spacing(2),
                            color: AppColors.gray550,
                          ),
                        ),
                        SizedBox(width: r.spacing(8)),
                        Text(
                          "กำลังกลับไปหน้าเข้าสู่ระบบ...",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.gray550),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
