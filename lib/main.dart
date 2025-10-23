import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DbToneApp());
}

class DbToneApp extends StatelessWidget {
  const DbToneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ling Six Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

/// Check if user is logged in
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const SoundSettingsPage();
        }
        return const LoginPage();
      },
    );
  }
}

//////////////////////
/// LOGIN PAGE
//////////////////////
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailOrUsernameController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _login() async {
    final emailOrUsername = emailOrUsernameController.text.trim();
    final password = passwordController.text.trim();

    try {
      String email = emailOrUsername;

      // 🔍 Allow username-based login
      if (!emailOrUsername.contains('@')) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: emailOrUsername)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          throw FirebaseAuthException(
              code: 'user-not-found', message: 'No user found with that username');
        }
        email = snap.docs.first['email'];
      }

      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔐 Check if email verified
      if (!userCred.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify your email before logging in.")),
        );
        return;
      }

      // ✅ Continue to app (handled by StreamBuilder in AuthGate)
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    }
  }

  /// 🌐 Google sign in
  Future<void> _signInWithGoogle() async {
    try {
      print("Starting Google Sign-In...");

      const iosClientId =
          '406340157010-j7rukhv5mugeklnn09b2reduiovkl09k.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'username': userCred.user!.displayName ?? "",
          'email': userCred.user!.email,
          'password': null,
          'isGoogleSignIn': true,
        });
      } else {
        await userDoc.update({
          'email': userCred.user!.email,
          'username': userCred.user!.displayName ?? "",
        });
      }

      print("✅ Google Sign-In successful: ${userCred.user!.email}");
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google Sign-In failed')),
      );
    } catch (e) {
      print("Google Sign-In error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Google Sign-In error')));
    }
  }

  /// 🔁 Resend verification email
  Future<void> _resendVerificationEmail() async {
    try {
      final emailOrUsername = emailOrUsernameController.text.trim();
      if (emailOrUsername.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your email or username.")),
        );
        return;
      }

      String email = emailOrUsername;
      if (!emailOrUsername.contains('@')) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: emailOrUsername)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No user found for that username.")),
          );
          return;
        }
        email = snap.docs.first['email'];
      }

      // Temporarily sign in to send verification email
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No account found for that email.")),
        );
        return;
      }

      final tempUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: passwordController.text.trim());
      await tempUser.user!.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification email sent to $email")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to resend email.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailOrUsernameController,
                decoration:
                    const InputDecoration(labelText: "Email or Username"),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: const Text("Login"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
              ),
              const SizedBox(height: 10),

              // 🔹 Forgot password button
              TextButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  final input = emailOrUsernameController.text.trim();

                  if (input.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please enter your email first.")),
                    );
                    return;
                  }

                  String email = input;
                  if (!input.contains('@')) {
                    final snap = await FirebaseFirestore.instance
                        .collection('users')
                        .where('username', isEqualTo: input)
                        .limit(1)
                        .get();

                    if (snap.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("No account found for that username.")),
                      );
                      return;
                    }
                    email = snap.docs.first['email'];
                  }

                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Password reset email sent to $email")),
                    );
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(e.message ?? "Error sending reset email")),
                    );
                  }
                },
                child: const Text("Forgot Password?"),
              ),

              // 🔁 Resend verification link
              TextButton(
                onPressed: _resendVerificationEmail,
                child: const Text("Resend Verification Email"),
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  );
                },
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


//////////////////////
/// SIGNUP PAGE
//////////////////////
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _signup() async {
  final email = emailController.text.trim();
  final username = usernameController.text.trim();
  final password = passwordController.text.trim();

  try {
    // Create user
    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // Save username + email in Firestore
    await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
      'username': username,
      'email': email,
    });

    // Send verification email
    await cred.user!.sendEmailVerification();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Verification email sent! Please check your inbox.")),
    );

    // Optionally log user out until verification
    await FirebaseAuth.instance.signOut();

    // Go back to login screen
    Navigator.pop(context);
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? 'Sign Up failed')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _signup, child: const Text("Sign Up")),
            ],
          ),
        ),
      ),
    );
  }
}

//////////////////////
/// SOUND SETTINGS PAGE
//////////////////////
class SoundSettingsPage extends StatefulWidget {
  const SoundSettingsPage({super.key});

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  final AudioPlayer _player = AudioPlayer();
  double? _selectedDb;
  final List<double> _dbOptions = [40, 50, 60, 70];

  Future<void> _testSound(double db) async {
    VolumeController().setVolume(db / 100);
    await _player.stop();
    await _player.play(AssetSource("ling6/ee.wav"));
  }

  void _lockDb() {
    if (_selectedDb == null) return;

    final min = _selectedDb! - 5;
    final max = _selectedDb! + 5;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ล็อคระดับเสียง!"),
        content: Text(
            "คุณได้เลือกระดับเสียง ${_selectedDb!.toInt()} dB (range $min–$max dB)"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ตกลง"),
          )
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตั้งค่าเสียง"),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("เลือกระดับเสียง",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: _dbOptions.map((db) {
                final selected = _selectedDb == db;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected ? Colors.amber : Colors.blue,
                    minimumSize: const Size(70, 70),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDb = db;
                    });
                  },
                  child: Text("${db.toInt()}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _selectedDb != null ? () => _testSound(_selectedDb!) : null,
              child: const Text("ทดสอบระดับเสียง"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _lockDb,
              child: const Text("ล็อกระดับเสียง"),
            ),
          ],
        ),
      ),
    );
  }
}
