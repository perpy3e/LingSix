import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _controller = TextEditingController();
  final _authService = AuthService();

  Future<void> _resetPassword() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    try {
      await _authService.sendPasswordReset(input);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent to $input")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: "Email or Username"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _resetPassword, child: const Text("Send Reset Link")),
        ]),
      ),
    );
  }
}
