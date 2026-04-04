import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';


import '../../app/router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../utils/snackbar_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _firestore = FirestoreService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailOrUsernameError;
  String? _passwordError;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailOrUsernameError = null;
      _passwordError = null;
    });
  }

  // -------------------------------------------------------------
  // EMAIL / PASSWORD LOGIN
  // -------------------------------------------------------------
  Future<void> _login() async {
    _clearErrors();
    final emailOrUsername = _emailOrUsernameController.text.trim();
    final password = _passwordController.text.trim();

    // Validate fields
    bool hasError = false;
    if (emailOrUsername.isEmpty) {
      setState(() => _emailOrUsernameError = 'โปรดกรอกอีเมลหรือชื่อบัญชีผู้ใช้ที่ลงทะเบียนไว้');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'โปรดกรอกรหัสผ่าน');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(emailOrUsername, password);
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;

      if (!user.emailVerified) {
        await _authService.logout();
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRouter.verifyPending,
          arguments: user.email,
        );
        return;
      }

      Navigator.pushReplacementNamed(context, AppRouter.startPage);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      // Show specific field errors based on error message
      if (errorMsg.toLowerCase().contains('user not found') ||
          errorMsg.toLowerCase().contains('username') ||
          errorMsg.toLowerCase().contains('email')) {
        setState(() => _emailOrUsernameError = errorMsg);
      } else if (errorMsg.toLowerCase().contains('password') ||
          errorMsg.toLowerCase().contains('incorrect')) {
        setState(() => _passwordError = errorMsg);
      } else {
        _showError(errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------
  // GOOGLE SIGN-IN
  // -------------------------------------------------------------
final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<void> _googleLogin() async {
  setState(() => _isGoogleLoading = true);

  try {
    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      print("❌ User cancelled");
      return;
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCred.user;
    if (user == null) throw Exception('Google user is null');

    final userDoc = await _firestore.getUserByUid(user.uid);

    if (userDoc == null) {
      await _firestore.addUser(
        user.uid,
        user.email ?? '',
        user.displayName ?? '',
        isGoogleSignIn: true,
      );

      Navigator.pushReplacementNamed(context, AppRouter.infodata);
      return;
    }

    final data = userDoc.data() as Map<String, dynamic>;

    if (data['profileCompleted'] != true) {
      Navigator.pushReplacementNamed(context, AppRouter.infodata);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRouter.startPage);

  } catch (e) {
    print("❌ ERROR: $e");
    _showError('เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
  } finally {
    if (mounted) setState(() => _isGoogleLoading = false);
  }
}
// -------------------------------------------------------------
  // GOOGLE SIGN-IN (END)
//-------------------------------------------------------------
  
  void _showError(String message) {
    SnackBarHelper.showError(context, message);
  }

  // -------------------------------------------------------------
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
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/common/logo/app_logo.png',
                    height: 200,
                    width: 200,
                  ),

                  const SizedBox(height: 60),
                  CustomTextField(
                    controller: _emailOrUsernameController,
                    hintText: 'อีเมล หรือ ชื่อผู้ใช้',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailOrUsernameError,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'รหัสผ่าน',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRouter.forgotPassword),
                      child: Text(
                        'ลืมรหัสผ่าน?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'เข้าสู่ระบบ',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'หรือ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).dividerColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _isGoogleLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 50,
                          child: SignInButton(
                            Buttons.google,
                            text: "เข้าสู่ระบบด้วยบัญชี Google",
                            onPressed: _googleLogin,
                          ),
                        ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "ยังไม่มีบัญชี? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRouter.signup),
                        child: Text(
                          'ลงทะเบียน',
                          style: (() {
                            final base = Theme.of(context).textTheme.bodyMedium;
                            final color = base?.color ?? Theme.of(context).colorScheme.onSurface;
                            return base?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: color,
                                ) ??
                                TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: color,
                                );
                          })(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


