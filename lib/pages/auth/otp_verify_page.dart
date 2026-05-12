import 'package:flutter/material.dart';
import 'package:lingsix/app/theme.dart';
import '../../app/router.dart';
import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/responsive.dart';


class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _otpController = TextEditingController();
  String? _otpError;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _otpError = null;
    });
  }

  Future<void> _verifyOtp() async {
    _clearErrors();
    final otp = _otpController.text.trim();

    // Validate field
    if (otp.isEmpty) {
      setState(() => _otpError = 'Please enter OTP code');
      return;
    }
    if (otp.length < 6) {
      setState(() => _otpError = 'OTP must be 6 digits');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("OTP verified successfully"),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            left: 20,
            right: 20,
          ),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRouter.login);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst("Exception: ", "");
      setState(() => _otpError = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    SnackBarHelper.show(context, "OTP sent to your email");
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

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
              Positioned(
                top: r.spacing(8),
                left: r.spacing(8),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: r.icon(30)), color: AppColors.blue800,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: r.pagePadding(horizontal: 20),
                  child: ResponsiveContent(
                    maxWidth: r.contentMaxWidth(phone: 500, tablet: 620),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: r.spacing(32)),
                        Text(
                          "OTP Verification",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        SizedBox(height: r.spacing(10)),
                        Text(
                          "Enter the 6-digit code sent to your email",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: r.spacing(28)),
                        CustomTextField(
                          controller: _otpController,
                          hintText: "Enter OTP Code",
                          prefixIcon: Icons.lock_outline,
                          keyboardType: TextInputType.number,
                          errorText: _otpError,
                        ),
                        SizedBox(height: r.spacing(20)),
                        CustomButton(
                          text: "Verify",
                          onPressed: _verifyOtp,
                          isLoading: _isLoading,
                        ),
                        SizedBox(height: r.spacing(16)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't receive the code? ",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: _resendOtp,
                              child: Text(
                                'Resend',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
