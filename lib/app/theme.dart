import 'package:flutter/material.dart';

class AppColors {
  // 🔵 Blue Palette
  static const blue900 = Color(0xFF1B465E);
  static const blue800 = Color(0xFF1B546F);
  static const blue700 = Color(0xFF166688);
  static const blue600 = Color(0xFF127EA8);
  static const blue500 = Color(0xFF129EC8);
  static const blue400 = Color(0xFF2EBBE2);
  static const blue300 = Color(0xFF64D3EF);
  static const blue200 = Color(0xFFAAE8F7);
  static const blue100 = Color(0xFFD2F5FB);
  static const blue10 = Color(0xFFEDFCFE);

  // 🟡 Yellow Palette
  static const yellow900 = Color(0xFF723811);
  static const yellow800 = Color(0xFF86450D);
  static const yellow700 = Color(0xFFA35705);
  static const yellow600 = Color(0xFFCC7D02);
  static const yellow500 = Color(0xFFECA406);
  static const yellow400 = Color(0xFFFDBE12);
  static const yellow300 = Color(0xFFFFD030);
  static const yellow200 = Color(0xFFFFE989);
  static const yellow100 = Color(0xFFFFF6C2);
  static const yellow10 = Color(0xFFFFFBE8);

  // ⚫ Gray Scale
  static const gray700 = Color(0xFF242424);
  static const gray550 = Color(0xFF6B6B6B);
  static const gray300 = Color(0xFFA3A3A3);
  static const gray100 = Color(0xFFE0E0E0);
  static const gray75 = Color(0xFFE8E8E8);
  static const gray50 = Color(0xFFEDEDED);
  static const gray25 = Color(0xFFF3F3F3);

  // ⚪ White
  static const white = Color(0xFFFFFFFF);

  // 🟥 Status
  static const error = Color(0xFFE1221C);
  static const warning = Color(0xFFF9BE00);
  static const success = Color(0xFF38A562);

  // 🎨 Accent Colors
  static const braveOrange = Color(0xFFFF681E);
  static const radiantYellow = Color(0xFFF89C22);
  static const pink = Color(0xFFF58FB5);
  static const purple = Color(0xFF5A2B83);
  static const purplePastel = Color(0xFFC6A1CF);
  static const skyBlue = Color(0xFF81D9F0);
  static const greenLight = Color(0xFF96CE2F);
  static const orange = Color(0xFFFEBB64);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.blue300,
    primaryColor: AppColors.yellow900,
    colorScheme: const ColorScheme.light(
      primary: AppColors.blue600,
      secondary: AppColors.yellow400,
      error: AppColors.error,
      surface: AppColors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.blue600,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: AppColors.gray25,
    dividerColor: AppColors.yellow700,
    dividerTheme: const DividerThemeData(
      color: AppColors.yellow700,
      thickness: 1,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.yellow900,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.yellow800,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.yellow800,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.yellow900),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.yellow700),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.yellow600),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.yellow900,
      ),
    ),
  );
}
