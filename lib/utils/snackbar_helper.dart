import 'package:flutter/material.dart';
import '../app/theme.dart';

class SnackBarHelper {
  /// Show a SnackBar at the TOP of the screen
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color bgColor = backgroundColor ?? AppColors.blue600;
    if (isError) bgColor = AppColors.error;
    if (isSuccess) bgColor = AppColors.success;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 20,
          right: 20,
        ),
        duration: duration,
      ),
    );
  }

  /// Show error SnackBar at the top
  static void showError(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  /// Show success SnackBar at the top
  static void showSuccess(BuildContext context, String message) {
    show(context, message, isSuccess: true);
  }
}
