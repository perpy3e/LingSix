import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../services/auth_service.dart';
import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../app/theme.dart';
import '../../utils/snackbar_helper.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

//controller
class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final _authService = AuthService();

  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _firstNameError;
  String? _lastNameError;
  String? _genderError;
  String? _birthdayError;

  String? _gender;
  DateTime? _birthday;

  // PASSWORD STATE
  double _passwordStrength = 0;
  String _passwordStrengthText = "";
  Color _passwordStrengthColor = AppColors.error;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  bool _showPasswordRules = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  //error
  void _clearErrors() {
    setState(() {
      _emailError = null;
      _usernameError = null;
      _passwordError = null;
      _firstNameError = null;
      _lastNameError = null;
      _genderError = null;
      _birthdayError = null;
    });
  }

  void _checkPassword(String password) {
    setState(() {
      _showPasswordRules = password.isNotEmpty;

      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));

      int score = 0;

      if (_hasMinLength) score++;
      if (_hasUppercase) score++;
      if (_hasNumber) score++;

      _passwordStrength = score / 3;

      if (score == 0) {
        _passwordStrengthText = "";
      } else if (score == 1) {
        _passwordStrengthText = "รหัสผ่านไม่ปลอดภัย";
        _passwordStrengthColor = AppColors.error;
      } else if (score == 2) {
        _passwordStrengthText = "รหัสผ่านปานกลาง";
        _passwordStrengthColor = AppColors.warning;
      } else if (score == 3) {
        _passwordStrengthText = "รหัสผ่านปลอดภัย";
        _passwordStrengthColor = AppColors.success;
      }
    });
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            color: met ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: met ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _birthday = date;
        _birthdayError = null;
      });
    }
  }

  Future<void> _signup() async {
    _clearErrors();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = 'กรุณากรอกอีเมล');
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'กรุณากรอกอีเมลให้ถูกต้อง');
      hasError = true;
    }

    if (username.isEmpty) {
      setState(() => _usernameError = 'กรุณากรอกชื่อผู้ใช้');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'กรุณากรอกรหัสผ่าน');
      hasError = true;
    } else if (!_hasMinLength || !_hasUppercase || !_hasNumber) {
      setState(() => _passwordError = 'รหัสผ่านยังไม่ปลอดภัย');
      hasError = true;
    }

    if (firstName.isEmpty) {
      setState(() => _firstNameError = 'กรุณากรอกชื่อ');
      hasError = true;
    }

    if (lastName.isEmpty) {
      setState(() => _lastNameError = 'กรุณากรอกนามสกุล');
      hasError = true;
    }

    if (_gender == null) {
      setState(() => _genderError = 'กรุณาเลือกเพศ');
      hasError = true;
    }

    if (_birthday == null) {
      setState(() => _birthdayError = 'กรุณาเลือกวันเกิด');
      hasError = true;
    }

    if (hasError) return;

    try {
      final user = await _authService.signUp(
        email: email,
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: _gender!,
        birthday: _birthday!,
      );

      if (!mounted || user == null) return;

      Navigator.pushNamed(
        context,
        AppRouter.verifyPending,
        arguments: user.email,
      );
    } catch (e) {
  if (!mounted) return;

  final msg = e.toString().replaceFirst("Exception: ", "").toLowerCase();

  if (msg.contains('email')) {
    await _authService.logout();
    if (!mounted) return;

    setState(() => _emailError = 'อีเมลนี้ถูกใช้งานแล้ว');
    return;
  }

  if (msg.contains('username')) {
    setState(() => _usernameError = 'ชื่อผู้ใช้นี้ถูกใช้งานแล้ว');
  } else if (msg.contains('password')) {
    setState(() => _passwordError = 'รหัสผ่านยังไม่ปลอดภัย');
  } else {
    SnackBarHelper.showError(
      context,
      'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
    );
  }
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
          child: Column(
            children: [
              // Fixed header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                    Expanded(
                      child: Text(
                        "สร้างบัญชีผู้ใช้",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.blue800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      CustomTextField(
                        controller: _emailController,
                        hintText: "อีเมล",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _usernameController,
                        hintText: "ชื่อผู้ใช้",
                        prefixIcon: Icons.person_outline,
                        errorText: _usernameError,
                      ),

                      const SizedBox(height: 16),
                      // PASSWORD FIELD
                      CustomTextField(
                        controller: _passwordController,
                        hintText: "รหัสผ่าน",
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        errorText: _passwordError,
                        onChanged: _checkPassword,

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.gray550,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      if (_showPasswordRules) ...[
                        const SizedBox(height: 8),

                        LinearProgressIndicator(
                          value: _passwordStrength,
                          minHeight: 6,
                          color: _passwordStrengthColor,
                          backgroundColor: Colors.grey.shade300,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _passwordStrengthText,
                          style: TextStyle(
                            color: _passwordStrengthColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        _buildRequirement(
                          "อย่างน้อย 8 ตัวอักษร",
                          _hasMinLength,
                        ),
                        _buildRequirement(
                          "ต้องมีตัวอักษรพิมพ์ใหญ่ (A-Z)",
                          _hasUppercase,
                        ),
                        _buildRequirement("ต้องมีตัวเลข (0-9)", _hasNumber),
                      ],

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("ข้อมูลส่วนตัว"),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      CustomTextField(
                        controller: _firstNameController,
                        hintText: "ชื่อจริง",
                        prefixIcon: Icons.badge_outlined,
                        errorText: _firstNameError,
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _lastNameController,
                        hintText: "นามสกุล",
                        prefixIcon: Icons.badge_outlined,
                        errorText: _lastNameError,
                      ),

                      const SizedBox(height: 16),
                      //Gender selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "เพศ",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.yellow900,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // GENDER SELECTOR
                          Row(
                            children: [
                              // MALE
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gender = 'male';
                                      _genderError = null;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: _gender == 'male'
                                          ? AppColors.yellow100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _gender == 'male'
                                            ? AppColors.yellow800
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.male,
                                          color: _gender == 'male'
                                              ? AppColors.yellow800
                                              : AppColors.gray550,
                                        ),

                                        const SizedBox(width: 8),

                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          style: TextStyle(
                                            color: _gender == 'male'
                                                ? AppColors.yellow900
                                                : AppColors.gray550,
                                            fontWeight: _gender == 'male'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          child: const Text("ชาย"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // FEMALE
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gender = 'female';
                                      _genderError = null;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: _gender == 'female'
                                          ? AppColors.yellow100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _gender == 'female'
                                            ? AppColors.yellow800
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.female,
                                          color: _gender == 'female'
                                              ? AppColors.yellow800
                                              : AppColors.gray550,
                                        ),

                                        const SizedBox(width: 8),

                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          style: TextStyle(
                                            color: _gender == 'female'
                                                ? AppColors.yellow900
                                                : AppColors.gray550,
                                            fontWeight: _gender == 'female'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          child: const Text("หญิง"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          //
                          if (_genderError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 12),
                              child: Text(
                                _genderError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: _pickBirthday,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: _birthdayError != null
                                ? Border.all(color: AppColors.error)
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(
                                _birthday == null
                                    ? "เลือกวันเกิด"
                                    : "${_birthday!.day}/${_birthday!.month}/${_birthday!.year}",
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      CustomButton(text: "ลงทะเบียน", onPressed: _signup),

                      const SizedBox(height: 40),
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
