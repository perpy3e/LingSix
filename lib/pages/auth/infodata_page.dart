import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../utils/snackbar_helper.dart';

class InfoDataPage extends StatefulWidget {
  const InfoDataPage({super.key});

  @override
  State<InfoDataPage> createState() => _InfoDataPageState();
}

class _InfoDataPageState extends State<InfoDataPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String? _gender;
  DateTime? _birthday;

  final _firestore = FirestoreService();

  Future<void> _pickBirthday() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _birthday = date);
    }
  }

  Future<void> _save() async {
    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        _gender == null ||
        _birthday == null) {
      SnackBarHelper.showError(context, "Please complete all fields");
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _firestore.updateUser(uid, {
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'gender': _gender,
      'birthday': _birthday,
      'profileCompleted': true, // ✅ IMPORTANT
    });

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/start-page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _gender,
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _gender = v),
              decoration: const InputDecoration(labelText: "Gender"),
            ),

            const SizedBox(height: 16),

            ListTile(
              title: Text(
                _birthday == null
                    ? "Select Birthday"
                    : "${_birthday!.day}/${_birthday!.month}/${_birthday!.year}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickBirthday,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
