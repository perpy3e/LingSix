import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/router.dart';
import '../../services/firestore_service.dart';


import '../../components/textfields/textfield.dart';
import '../../components/button/button.dart';
import '../../app/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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

  String? _firstNameError;
  String? _lastNameError;
  String? _genderError;
  String? _birthdayError;

  final _firestore = FirestoreService();

  Future<void> _pickBirthday() async {

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _birthday = date;
        _birthdayError = null;
      });
    }
  }

  Future<void> _save() async {

  setState(() {
    _firstNameError = null;
    _lastNameError = null;
    _genderError = null;
    _birthdayError = null;
  });

  if (_firstName.text.trim().isEmpty) {
    setState(() => _firstNameError = "กรุณากรอกชื่อจริง");
  }

  if (_lastName.text.trim().isEmpty) {
    setState(() => _lastNameError = "กรุณากรอกนามสกุล");
  }

  if (_gender == null) {
    setState(() => _genderError = "กรุณาเลือกเพศ");
  }

  if (_birthday == null) {
    setState(() => _birthdayError = "กรุณาเลือกวันเกิด");
  }

  if (_firstNameError != null ||
      _lastNameError != null ||
      _genderError != null ||
      _birthdayError != null) {
    return;
  }

  final uid = FirebaseAuth.instance.currentUser!.uid;

  await _firestore.updateUser(uid, {

    'firstName': _firstName.text.trim(),
    'lastName': _lastName.text.trim(),
    'gender': _gender,

    // birthday fix
    'birthday': Timestamp.fromDate(_birthday!),

    'profileCompleted': true,

  });

  if (!mounted) return;

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
                            "เพศ",
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
                        onTap: _pickBirthday,
                        child: Container(

                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(
                              color: _birthdayError != null
                                  ? AppColors.error
                                  : AppColors.gray300,
                            ),
                          ),

                          child: Row(

                            children: [

                              const Icon(Icons.calendar_today),

                              const SizedBox(width: 12),

                              Text(
                                _birthday == null
                                    ? "เลือกวันเกิด"
                                    : "${_birthday!.day}/${_birthday!.month}/${_birthday!.year}",
                              ),

                            ],
                          ),
                        ),
                      ),

                      if (_birthdayError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 12),
                          child: Text(
                            _birthdayError!,
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
