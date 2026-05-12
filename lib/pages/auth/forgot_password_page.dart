import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/responsive.dart';

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
      SnackBarHelper.showSuccess(
        context,
        "ส่งอีเมลรีเซ็ตรหัสผ่านไปที่ $input แล้ว",
      );
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
          child: Stack(
            children: [
              Positioned(
                top: r.spacing(8),
                left: r.spacing(8),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, size: r.icon(30)),
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
                          "ลืมรหัสผ่าน",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        SizedBox(height: r.spacing(10)),
                        Text(
                          "กรอกอีเมลหรือชื่อผู้ใช้ของคุณ เพื่อรับลิงก์สำหรับรีเซ็ตรหัสผ่าน",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: r.spacing(28)),
                        CustomTextField(
                          controller: _controller,
                          hintText: "อีเมล หรือ ชื่อผู้ใช้",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        SizedBox(height: r.spacing(20)),
                        CustomButton(
                          text: "ส่งลิงก์รีเซ็ตรหัสผ่าน",
                          onPressed: _resetPassword,
                          isLoading: _isLoading,
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
