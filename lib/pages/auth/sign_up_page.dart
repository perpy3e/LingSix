import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../app/theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

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

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

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

    // Validate fields
    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter email');
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email');
      hasError = true;
    }
    if (username.isEmpty) {
      setState(() => _usernameError = 'Please enter username');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter password');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      hasError = true;
    }
    if (firstName.isEmpty) {
      setState(() => _firstNameError = 'Please enter first name');
      hasError = true;
    }
    if (lastName.isEmpty) {
      setState(() => _lastNameError = 'Please enter last name');
      hasError = true;
    }
    if (_gender == null) {
      setState(() => _genderError = 'Please select gender');
      hasError = true;
    }
    if (_birthday == null) {
      setState(() => _birthdayError = 'Please select birthday');
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
      return;
    }

      if (!mounted || user == null) return;

      // To verify pending page & back to sign up
      Navigator.pushNamed(context, '/verify-pending', arguments: user.email);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst("Exception: ", "");
      // Show specific field errors based on error message
      if (msg.toLowerCase().contains('email')) {
        setState(() => _emailError = msg);
      } else if (msg.toLowerCase().contains('username')) {
        setState(() => _usernameError = msg);
      } else if (msg.toLowerCase().contains('password')) {
        setState(() => _passwordError = msg);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/bgMain.png'),
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
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
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
                      Text(
                        "Create an Account",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 40),

                      // Email
                      CustomTextField(
                        controller: _emailController,
                        hintText: "Email",
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 16),

                      // Username
                      CustomTextField(
                        controller: _usernameController,
                        hintText: "Username",
                        prefixIcon: Icons.person_outline,
                        errorText: _usernameError,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      CustomTextField(
                        controller: _passwordController,
                        hintText: "Password",
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        errorText: _passwordError,
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Personal Info",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // First Name
                      CustomTextField(
                        controller: _firstNameController,
                        hintText: "First Name",
                        prefixIcon: Icons.badge_outlined,
                        errorText: _firstNameError,
                      ),
                      const SizedBox(height: 16),

                      // Last Name
                      CustomTextField(
                        controller: _lastNameController,
                        hintText: "Last Name",
                        prefixIcon: Icons.badge_outlined,
                        errorText: _lastNameError,
                      ),
                      const SizedBox(height: 16),

                      // Gender Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: _genderError != null
                                  ? Border.all(color: AppColors.error, width: 1)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _gender = 'male';
                                      _genderError = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _gender == 'male'
                                            ? AppColors.skyBlue.withValues(
                                                alpha: 0.3
                                              )
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        border: _gender == 'male'
                                            ? Border.all(
                                                color: AppColors.blue600,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.male,
                                            color: _gender == 'male'
                                                ? AppColors.blue600
                                                : AppColors.gray550,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Male',
                                            style: TextStyle(
                                              color: _gender == 'male'
                                                  ? AppColors.blue800
                                                  : AppColors.gray550,
                                              fontWeight: _gender == 'male'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _gender = 'female';
                                      _genderError = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _gender == 'female'
                                            ? AppColors.pink.withValues(
                                                alpha: 0.3
                                              )
                                            : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                        border: _gender == 'female'
                                            ? Border.all(
                                                color: AppColors.pink,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.female,
                                            color: _gender == 'female'
                                                ? AppColors.pink
                                                : AppColors.gray550,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Female',
                                            style: TextStyle(
                                              color: _gender == 'female'
                                                  ? AppColors.pink
                                                  : AppColors.gray550,
                                              fontWeight: _gender == 'female'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

                      // Birthday Picker
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _pickBirthday,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: _birthdayError != null
                                    ? Border.all(
                                        color: AppColors.error,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: _birthdayError != null
                                        ? AppColors.error
                                        : AppColors.gray550,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _birthday == null
                                        ? 'Select Birthday'
                                        : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _birthday == null
                                          ? AppColors.gray300
                                          : AppColors.yellow900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_birthdayError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 12),
                              child: Text(
                                _birthdayError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      CustomButton(text: "Sign Up", onPressed: _signup),
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
