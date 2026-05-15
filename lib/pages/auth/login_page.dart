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
import 'package:provider/provider.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../utils/responsive.dart';

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
      setState(
        () => _emailOrUsernameError =
            'โปรดกรอกอีเมลหรือชื่อบัญชีผู้ใช้ที่ลงทะเบียนไว้',
      );
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

      //await context.read<ThemeProvider>()
      // .syncThemeStatusFromFirestore(user.uid);

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

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCred.user;
      if (user == null) throw Exception('Google user is null');

      final userDoc = await _firestore.getUserByUid(user.uid);

      //
      if (userDoc == null) {
        await _firestore.addUser(
          user.uid,
          user.email ?? '',
          user.displayName ?? '',
          authProvider: 'google',
        );

        Navigator.pushReplacementNamed(context, AppRouter.infodata);
        return;
      }

      //
     final data = userDoc.data() as Map<String, dynamic>?;

final hasProfile =
    data != null &&
    data['firstName'] != null &&
    data['firstName'].toString().trim().isNotEmpty &&
    data['lastName'] != null &&
    data['lastName'].toString().trim().isNotEmpty;
      if (!hasProfile) {
        Navigator.pushReplacementNamed(context, AppRouter.infodata);
        return;
      }

      // ✅ sync ตอนเข้า app จริง
      await context.read<ThemeProvider>().syncThemeStatusFromFirestore(
        user.uid,
      );

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

  
 // -------------------------------------------------------------
// APPLE SIGN-IN

Future<void> _appleLogin() async {
  setState(() => _isGoogleLoading = true);

  try {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCred = await FirebaseAuth.instance.signInWithCredential(
      oauthCredential,
    );

    final user = userCred.user;

    if (user == null) {
      throw Exception("Apple user is null");
    }

    final userDoc = await _firestore.getUserByUid(user.uid);

    // -------------------------------------------------
    // NEW USER
    // -------------------------------------------------
   // -------------------------------------------------
// NEW USER
// -------------------------------------------------
if (userDoc == null) {

 final emailPrefix =
    (user.email != null && user.email!.contains('@'))
        ? user.email!.split('@').first
        : 'AppleUser';

final displayNameParts =
    (user.displayName ?? '').trim().split(' ');

final safeDisplayFirstName =
    displayNameParts.isNotEmpty &&
            displayNameParts.first.trim().isNotEmpty
        ? displayNameParts.first.trim()
        : '';

final firstName =
    appleCredential.givenName?.trim().isNotEmpty == true
        ? appleCredential.givenName!.trim()
        : safeDisplayFirstName.isNotEmpty
            ? safeDisplayFirstName
            : emailPrefix;

final safeLastName =
    displayNameParts.length > 1
        ? displayNameParts.sublist(1).join(' ').trim()
        : '';

final lastName =
    appleCredential.familyName?.trim().isNotEmpty == true
        ? appleCredential.familyName!.trim()
        : safeLastName;

  await _firestore.addUser(
  user.uid,
  user.email ?? '',
  user.email ?? '',
  authProvider: 'apple',
  firstName: firstName,
  lastName: lastName,
);
await FirebaseAuth.instance.currentUser?.reload();

if (!mounted) return;

await context.read<ThemeProvider>()
    .syncThemeStatusFromFirestore(user.uid);

Navigator.pushReplacementNamed(
  context,
  AppRouter.startPage,
);

return;
}
    // -------------------------------------------------
    // EXISTING USER
    // -------------------------------------------------

    await context.read<ThemeProvider>().syncThemeStatusFromFirestore(
      user.uid,
    );

    if (!mounted) return;

    //  GO START PAGE
    Navigator.pushReplacementNamed(
      context,
      AppRouter.startPage,
    );
  } catch (e) {
    print("APPLE LOGIN ERROR: $e");

    _showError('เข้าสู่ระบบด้วย Apple ไม่สำเร็จ');
  } finally {
    if (mounted) {
      setState(() => _isGoogleLoading = false);
    }
  }
}

// -------------------------------------------------------------
  // -----------------------------------------------------------

  void _showError(String message) {
    SnackBarHelper.showError(context, message);
  }

  // -------------------------------------------------------------
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
              padding: r.pagePadding(horizontal: 20, min: 10, maxPhone: 22),
              child: ResponsiveContent(
                maxWidth: r.contentMaxWidth(phone: 480, tablet: 620),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: r.spacing(20)),

                    Image.asset(
                      'assets/common/logo/app_logo.png',
                      height: r.spacing(180).clamp(110, 240),
                      width: r.spacing(180).clamp(110, 240),
                    ),

                    SizedBox(height: r.spacing(24)),
                    CustomTextField(
                      controller: _emailOrUsernameController,
                      hintText: 'อีเมล หรือ ชื่อผู้ใช้',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailOrUsernameError,
                    ),
                    SizedBox(height: r.spacing(14)),

                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'รหัสผ่าน',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      errorText: _passwordError,
                    ),
                    SizedBox(height: r.spacing(10)),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRouter.forgotPassword,
                        ),
                        child: Text(
                          'ลืมรหัสผ่าน?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),

                    SizedBox(height: r.spacing(16)),

                    CustomButton(
                      text: 'เข้าสู่ระบบ',
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),
                    SizedBox(height: r.spacing(12)),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.spacing(12),
                          ),
                          child: Text(
                            'หรือ',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).dividerColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: r.spacing(12)),

                    _isGoogleLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            height: r.buttonHeight(48),
                            child: SignInButton(
                              Buttons.google,
                              text: "เข้าสู่ระบบด้วยบัญชี Google",
                              onPressed: _googleLogin,
                            ),
                          ),
                    SizedBox(height: r.spacing(16)),

                    SizedBox(
                      height: r.buttonHeight(48),
                      child: SignInButton(
                        Buttons.apple,
                        text: "เข้าสู่ระบบด้วย Apple",
                        onPressed: _appleLogin,
                      ),
                    ),

                    SizedBox(height: r.spacing(16)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "ยังไม่มีบัญชี? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, AppRouter.signup),
                          child: Text(
                            'ลงทะเบียน',
                            style: (() {
                              final base = Theme.of(
                                context,
                              ).textTheme.bodyMedium;
                              final color =
                                  base?.color ??
                                  Theme.of(context).colorScheme.onSurface;
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
                    SizedBox(height: r.spacing(20)),
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
