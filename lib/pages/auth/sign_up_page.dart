import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../services/auth_service.dart';
import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../app/theme.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/responsive.dart';

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
  String? _birthYearError;

  String? _gender;
  int? _birthYear;

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
      _birthYearError = null;
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

  Future<void> _pickBirthYear() async {
    final currentYear = DateTime.now().year;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              const SizedBox(height: 16),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'เลือกปีเกิด',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    final year = currentYear - index;
                    final thaiYear = year + 543;

                    return ListTile(
                      title: Center(
                        child: Text(
                          thaiYear.toString(),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),

                      onTap: () {
                        setState(() {
                          _birthYear = year; // store ค.ศ.
                          _birthYearError = null;
                        });

                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

    if (hasError) return;

    try {
      final user = await _authService.signUp(
        email: email,
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: _gender,
        birthYear: _birthYear,
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
              // Fixed header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.spacing(8),
                  vertical: r.spacing(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, size: r.icon(30)), color: AppColors.blue800,
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
                    SizedBox(width: r.spacing(48)), // Balance the back button
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: r.pagePadding(horizontal: 20),
                  child: ResponsiveContent(
                    maxWidth: r.contentMaxWidth(phone: 520, tablet: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: r.spacing(20)),

                        CustomTextField(
                          controller: _emailController,
                          hintText: "อีเมล",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),

                        SizedBox(height: r.spacing(16)),

                        CustomTextField(
                          controller: _usernameController,
                          hintText: "ชื่อผู้ใช้",
                          prefixIcon: Icons.person_outline,
                          errorText: _usernameError,
                        ),

                        SizedBox(height: r.spacing(16)),
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
                          SizedBox(height: r.spacing(8)),

                          LinearProgressIndicator(
                            value: _passwordStrength,
                            minHeight: 6,
                            color: _passwordStrengthColor,
                            backgroundColor: Colors.grey.shade300,
                          ),

                          SizedBox(height: r.spacing(6)),

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

                        SizedBox(height: r.spacing(24)),

                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.spacing(16),
                              ),
                              child: Text("ข้อมูลส่วนตัว"),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        SizedBox(height: r.spacing(24)),

                        CustomTextField(
                          controller: _firstNameController,
                          hintText: "ชื่อจริง",
                          prefixIcon: Icons.badge_outlined,
                          errorText: _firstNameError,
                        ),

                        SizedBox(height: r.spacing(16)),

                        CustomTextField(
                          controller: _lastNameController,
                          hintText: "นามสกุล",
                          prefixIcon: Icons.badge_outlined,
                          errorText: _lastNameError,
                        ),

                        SizedBox(height: r.spacing(16)),
                        //Gender selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "เพศ (ไม่บังคับ)",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.yellow900,
                              ),
                            ),

                            SizedBox(height: r.spacing(8)),

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
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
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
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
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
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  left: 12,
                                ),
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

                        SizedBox(height: r.spacing(16)),

                        GestureDetector(
                          onTap: _pickBirthYear,
                          child: Container(
                            padding: EdgeInsets.all(r.spacing(16)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: _birthYearError != null
                                  ? Border.all(color: AppColors.error)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                SizedBox(width: r.spacing(12)),
                                Text(
                                  _birthYear == null
                                      ? "เลือกปีเกิด (ไม่บังคับ)"
                                      : "${_birthYear! + 543}",
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: r.spacing(24)),

                        CustomButton(text: "ลงทะเบียน", onPressed: _signup),

                        SizedBox(height: r.spacing(32)),
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
