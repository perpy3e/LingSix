import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  String? _gender;
  DateTime? _birthday;

  final _auth = AuthService();

  Future<void> _pickBirthday() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _birthday = date);
  }

  Future<void> _signup() async {
    if (_gender == null || _birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final user = await _auth.signUp(
        email: _email.text.trim(),
        username: _username.text.trim(),
        password: _password.text.trim(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        gender: _gender!,
        birthday: _birthday!,
      );

      if (!mounted || user == null) return;

      Navigator.pushNamed(
        context,
        '/verify-pending',
        arguments: user.email,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),

            const Divider(height: 30),

            TextField(controller: _firstName, decoration: const InputDecoration(labelText: 'First Name')),
            TextField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last Name')),

            const SizedBox(height: 16),

            ToggleButtons(
              isSelected: [_gender == 'male', _gender == 'female'],
              onPressed: (i) =>
                  setState(() => _gender = i == 0 ? 'male' : 'female'),
              children: const [
                Padding(padding: EdgeInsets.all(12), child: Text('♂ Male')),
                Padding(padding: EdgeInsets.all(12), child: Text('♀ Female')),
              ],
            ),

            const SizedBox(height: 16),

            ListTile(
              title: Text(
                _birthday == null
                    ? 'Select Birthday'
                    : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickBirthday,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _signup,
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
