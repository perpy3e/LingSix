import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../app/theme.dart';
import '../../utils/snackbar_helper.dart';
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
  final user = FirebaseAuth.instance.currentUser;

  // if user is null → go login
  if (user == null) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }

  final doc = await _firestore.getUserByUid(user.uid);

  // 
  if (doc == null || doc.data() == null) {
    if (!mounted) return;
    setState(() {
      userData = {}; // stop loading spinner
    });
    return;
  }

  final data = doc.data() as Map<String, dynamic>;

  if (!mounted) return;
  setState(() {
    userData = data;
    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _gender = data['gender'] ?? 'Other';
    _birthday = (data['birthday'] as Timestamp?)?.toDate();
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

    SnackBarHelper.showSuccess(context, "อัปเดตโปรไฟล์สำเร็จ");
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.gray700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (date != null) {
      setState(() => _birthday = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/common/bg/profile.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.blue600),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/common/bg/profile.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      "โปรไฟล์",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.blue800,
                          ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Body content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Avatar with gradient border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.blue400, AppColors.blue600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue600.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: AppColors.blue100,
                            child: Text(
                              "${_firstNameController.text.isNotEmpty ? _firstNameController.text[0].toUpperCase() : ''}"
                              "${_lastNameController.text.isNotEmpty ? _lastNameController.text[0].toUpperCase() : ''}",
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Full Name Display
                      Text(
                        "${_firstNameController.text} ${_lastNameController.text}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.blue600.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _gender ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.blue700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.person_outline_rounded, color: AppColors.blue600),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "ข้อมูลส่วนตัว",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Edit button
                                  GestureDetector(
                                    onTap: () => setState(() => _edit = !_edit),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _edit ? AppColors.braveOrange : AppColors.blue100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _edit ? Icons.close_rounded : Icons.edit_rounded,
                                        color: _edit ? Colors.white : AppColors.blue600,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: AppColors.gray75),
                              const SizedBox(height: 12),
                              _buildInfoField("ชื่อจริง", _firstNameController, Icons.badge_outlined),
                              _buildInfoField("นามสกุล", _lastNameController, Icons.badge_outlined),
                              _buildGenderDropdown(),
                              _buildBirthdayPicker(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (_edit) _buildEditButtons() else _buildActionButtons(),

                      const SizedBox(height: 30),
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

  Widget _buildInfoField(String label, TextEditingController controller, IconData icon) {
    if (!_edit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue400, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray550,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.text.isEmpty ? '-' : controller.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.gray700),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.gray550),
          prefixIcon: Icon(icon, color: AppColors.blue400),
          filled: true,
          fillColor: AppColors.gray25,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.blue400, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    if (!_edit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.wc_outlined, color: AppColors.blue400, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "เพศ",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray550,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _gender ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: ['Male', 'Female', 'Other'].contains(_gender) ? _gender : null,
        items: ['Male', 'Female', 'Other']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (val) => setState(() => _gender = val),
        style: const TextStyle(color: AppColors.gray700, fontSize: 16),
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: "เพศ",
          labelStyle: const TextStyle(color: AppColors.gray550),
          prefixIcon: const Icon(Icons.wc_outlined, color: AppColors.blue400),
          filled: true,
          fillColor: AppColors.gray25,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.blue400, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildBirthdayPicker() {
    if (!_edit) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: AppColors.blue400, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "อายุ",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray550,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _birthday != null ? _age(_birthday!) : '-',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: _pickBirthday,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "วันเกิด",
            labelStyle: const TextStyle(color: AppColors.gray550),
            prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.blue400),
            suffixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.blue400),
            filled: true,
            fillColor: AppColors.gray25,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          child: Text(
            _birthday != null
                ? "${_birthday!.day}/${_birthday!.month}/${_birthday!.year}"
                : "เลือกวันเกิด",
            style: TextStyle(
              fontSize: 16,
              color: _birthday != null ? AppColors.gray700 : AppColors.gray550,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text(
                "บันทึก",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.braveOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _saveProfile,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close_rounded, color: AppColors.gray550),
              label: const Text(
                "ยกเลิก",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray550,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.gray300, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => setState(() => _edit = false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text(
              "ออกจากระบบ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.error, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
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
        ),
      ],
    );
  }
}
