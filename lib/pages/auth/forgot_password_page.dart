import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../utils/snackbar_helper.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _controller = TextEditingController();
  final _authService = AuthService();
  String? _emailError;
  bool _isLoading = false;

  void _clearErrors() {
    setState(() {
      _emailError = null;
    });
  }

  Future<void> _resetPassword() async {
    _clearErrors();
    final input = _controller.text.trim();

    // Validate field
    if (input.isEmpty) {
      setState(() => _emailError = 'กรุณากรอกอีเมลหรือชื่อผู้ใช้');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordReset(input);
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, "ส่งอีเมลรีเซ็ตรหัสผ่านไปที่ $input แล้ว");
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst("Exception: ", "");
      setState(() => _emailError = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 30),
                  onPressed: () => Navigator.pop(context),
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
                      Text(
                        "ลืมรหัสผ่าน",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "กรอกอีเมลหรือชื่อผู้ใช้ของคุณ เพื่อรับลิงก์สำหรับรีเซ็ตรหัสผ่าน",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 40),
                      CustomTextField(
                        controller: _controller,
                        hintText: "อีเมล หรือ ชื่อผู้ใช้",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "ส่งลิงก์รีเซ็ตรหัสผ่าน",
                        onPressed: _resetPassword,
                        isLoading: _isLoading,
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
