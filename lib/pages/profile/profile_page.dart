import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _edit = false;
  Map<String, dynamic>? userData;
  final _firestore = FirestoreService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _gender;
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _firestore.getUserByUid(uid);
    final data = doc?.data() as Map<String, dynamic>?;
    if (data == null) return;

    final firstName = (data['firstName'] ?? '') as String;
    final lastName = (data['lastName'] ?? '') as String;
    final gender = (data['gender'] ?? 'Other') as String;
    final birthday = (data['birthday'] as Timestamp?)?.toDate();

    if (!mounted) return;
    setState(() {
      userData = data;
      _firstNameController.text = firstName;
      _lastNameController.text = lastName;
      _gender = gender;
      _birthday = birthday;
    });
  }

  String _age(DateTime b) {
    final now = DateTime.now();
    int y = now.year - b.year;
    int m = now.month - b.month;
    if (m < 0) {
      y--;
      m += 12;
    }
    return "$y years $m months";
  }

  Future<void> _saveProfile() async {
    if (_birthday == null) return;

    final updatedData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'gender': _gender,
      'birthday': _birthday,
    };

    await _firestore.updateUser(
      FirebaseAuth.instance.currentUser!.uid,
      updatedData,
    );

    if (!mounted) return;

    setState(() {
      _edit = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (!mounted) return;
    if (date != null) {
      setState(() => _birthday = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/start-page');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.teal[200],
              child: Text(
                "${_firstNameController.text.isNotEmpty ? _firstNameController.text[0] : ''}"
                "${_lastNameController.text.isNotEmpty ? _lastNameController.text[0] : ''}",
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField("First Name", _firstNameController),
                    _buildTextField("Last Name", _lastNameController),
                    _buildGenderDropdown(),
                    _buildBirthdayPicker(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _edit ? _buildEditButtons() : _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    if (!_edit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text("$label: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(controller.text)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    if (!_edit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Text("Gender: ",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_gender ?? '-'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
       initialValue : ['Male', 'Female', 'Other'].contains(_gender) ? _gender : null,
        items: ['Male', 'Female', 'Other']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (val) => setState(() => _gender = val),
        decoration: InputDecoration(
          labelText: "Gender",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBirthdayPicker() {
    if (!_edit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Text("Age: ",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_birthday != null ? _age(_birthday!) : '-'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: _pickBirthday,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Birthday",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _birthday != null
                ? "${_birthday!.day}/${_birthday!.month}/${_birthday!.year}"
                : "Select Birthday",
          ),
        ),
      ),
    );
  }

  Widget _buildEditButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text("Save"),
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          onPressed: _saveProfile,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel),
          label: const Text("Cancel"),
          onPressed: () => setState(() => _edit = false),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text("Edit Profile"),
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          onPressed: () => setState(() => _edit = true),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text("Logout"),
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await AuthService().logout();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}
