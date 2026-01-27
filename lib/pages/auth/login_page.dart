import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';

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
      setState(() => _emailOrUsernameError = 'Please enter email or username');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter password');
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
          '/verify-pending',
          arguments: user.email,
        );
        return;
      }

      Navigator.pushReplacementNamed(context, '/start-page');
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
Future<void> _googleLogin() async {
  setState(() => _isGoogleLoading = true);

  try {
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCred.user;
    if (user == null) throw Exception('Google user is null');

    final userDoc = await _firestore.getUserByUid(user.uid);

    // 🆕 NEW USER
    if (userDoc == null) {
      await _firestore.addUser(
        user.uid,
        user.email ?? '',
        user.displayName ?? '',
        isGoogleSignIn: true,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/infodata');
      return;
    }

    final data = userDoc.data() as Map<String, dynamic>;

    // new sign-in
    if (data['profileCompleted'] != true) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/infodata');
      return;
    }

    // profile completed
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/start-page');
  } catch (e) {
    if (!mounted) return;
    _showError('Google Sign-In failed\n$e');
  } finally {
    if (mounted) setState(() => _isGoogleLoading = false);
  }
}


  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/bgLogin.png'),
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

                  Text(
                    'LingSix',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 60),

                  CustomTextField(
                    controller: _emailOrUsernameController,
                    hintText: 'Email or Username',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailOrUsernameError,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      child: Text(
                        'Forgot Password?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Login',
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
                          'OR',
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
                            Buttons.Google,
                            text: "Sign up with Google",
                            onPressed: _googleLogin,
                          ),
                        ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          'Sign Up',
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
