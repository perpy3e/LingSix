import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

import '../../app/theme.dart';
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

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // EMAIL / PASSWORD LOGIN
  // -------------------------------------------------------------
  Future<void> _login() async {
    final emailOrUsername = _emailOrUsernameController.text.trim();
    final password = _passwordController.text.trim();

    if (emailOrUsername.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

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
      _showError(e.toString());
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

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

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
      }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo or App Name
                  Text(
                    'LingSix',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 60),

                  // Email/Username TextField
                  CustomTextField(
                    controller: _emailOrUsernameController,
                    hintText: 'Email or Username',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password TextField
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password
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

                  // Login Button
                  CustomButton(
                    text: 'Login',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.yellow700,
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

                  // Sign Up Link
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
