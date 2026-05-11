import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/router.dart';
import '../../services/firestore_service.dart';


import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../app/theme.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/providers/theme_provider.dart';

class InfoDataPage extends StatefulWidget {
  const InfoDataPage({super.key});

  @override
  State<InfoDataPage> createState() => _InfoDataPageState();
}

class _InfoDataPageState extends State<InfoDataPage> {

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  String? _gender;
  int? _birthYear;

  String? _firstNameError;
  String? _lastNameError;
  String? _genderError;
  String? _birthYearError;

  final _firestore = FirestoreService();

Future<void> _pickBirthYear() async {
  final currentYear = DateTime.now().year;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return SizedBox(
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 16),

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'เลือกปีเกิด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: 100,
                itemBuilder: (context, index) {
                  final year = currentYear - index;
                  final thaiYear = year + 543;

                  return ListTile(
                    title: Center(
                      child: Text(
                        thaiYear.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),

                    onTap: () {
                      setState(() {
                        _birthYear = year; // store ค.ศ.
                        _birthYearError = null;
                      });

                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> _save() async {

  setState(() {
    _firstNameError = null;
    _lastNameError = null;
    _genderError = null;
    _birthYearError = null;
  });

  if (_firstName.text.trim().isEmpty) {
    setState(() => _firstNameError = "กรุณากรอกชื่อจริง");
  }

  if (_lastName.text.trim().isEmpty) {
    setState(() => _lastNameError = "กรุณากรอกนามสกุล");
  }

  
  

  if (_firstNameError != null ||
      _lastNameError != null ||
      _genderError != null ||
      _birthYearError != null) {
    return;
  }

  final uid = FirebaseAuth.instance.currentUser!.uid;

  await _firestore.updateUser(uid, {

    'firstName': _firstName.text.trim(),
    'lastName': _lastName.text.trim(),
    'gender': _gender,

    // birthday fix
    'birthYear': _birthYear,
    'profileCompleted': true,

  });

  if (!mounted) return;

  await context.read<ThemeProvider>()
    .syncThemeStatusFromFirestore(uid);

Navigator.pushReplacementNamed(context, AppRouter.startPage);
}


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      //
       appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new,
        color: Colors.black,
      ),
      onPressed: () async {

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.login,
          (route) => false,
        );

      },
    ),
  ),

  extendBodyBehindAppBar: true,
//
      body: Container(

        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/common/bg/login.png'),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(

          child: Stack(

            children: [

              Center(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [

                      const SizedBox(height: 40),

                      Text(
                        "ข้อมูลส่วนตัว",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),

                      const SizedBox(height: 40),

                      // FIRST NAME
                      CustomTextField(
                        controller: _firstName,
                        hintText: "ชื่อจริง",
                        prefixIcon: Icons.badge_outlined,
                        errorText: _firstNameError,
                      ),

                      const SizedBox(height: 16),

                      // LAST NAME
                      CustomTextField(
                        controller: _lastName,
                        hintText: "นามสกุล",
                        prefixIcon: Icons.badge_outlined,
                        errorText: _lastNameError,
                      ),

                      const SizedBox(height: 16),

                      // GENDER
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "เพศ (ไม่บังคับ)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.yellow900,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gender = 'male';
                                      _genderError = null;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: _gender == 'male'
                                          ? AppColors.yellow100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _gender == 'male'
                                            ? AppColors.yellow800
                                            : AppColors.gray300,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [

                                        Icon(
                                          Icons.male,
                                          color: _gender == 'male'
                                              ? AppColors.yellow800
                                              : AppColors.gray550,
                                        ),

                                        const SizedBox(width: 8),

                                        Text(
                                          "ชาย",
                                          style: TextStyle(
                                            color: _gender == 'male'
                                                ? AppColors.yellow900
                                                : AppColors.gray550,
                                            fontWeight: _gender == 'male'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gender = 'female';
                                      _genderError = null;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: _gender == 'female'
                                          ? AppColors.yellow100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _gender == 'female'
                                            ? AppColors.yellow800
                                            : AppColors.gray300,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [

                                        Icon(
                                          Icons.female,
                                          color: _gender == 'female'
                                              ? AppColors.yellow800
                                              : AppColors.gray550,
                                        ),

                                        const SizedBox(width: 8),

                                        Text(
                                          "หญิง",
                                          style: TextStyle(
                                            color: _gender == 'female'
                                                ? AppColors.yellow900
                                                : AppColors.gray550,
                                            fontWeight: _gender == 'female'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          ),

                          if (_genderError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 12),
                              child: Text(
                                _genderError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                        ],
                      ),

                      const SizedBox(height: 16),

                      // BIRTHDAY
                      GestureDetector(
                        onTap: _pickBirthYear,
                        child: Container(

                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(
                              color: _birthYearError != null
                                  ? AppColors.error
                                  : AppColors.gray300,
                            ),
                          ),

                          child: Row(

                            children: [

                              const Icon(Icons.calendar_today),

                              const SizedBox(width: 12),

                              Text(
                                _birthYear == null
    ? "เลือกปีเกิด (ไม่บังคับ)"
    : "${_birthYear! + 543}",
                              ),

                            ],
                          ),
                        ),
                      ),

                      if (_birthYearError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 12),
                          child: Text(
                            _birthYearError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      CustomButton(
                        text: "ต่อไป",
                        onPressed: _save,
                      ),

                      const SizedBox(height: 40),

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
}
