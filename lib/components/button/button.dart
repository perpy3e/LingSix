import 'package:flutter/material.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/utils/responsive.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final radius = r.spacing(12);

    return SizedBox(
      width: double.infinity,
      height: r.buttonHeight(56),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.yellow200,
          foregroundColor: textColor ?? AppColors.yellow700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(
              color: Colors.white,
              width: r.spacing(2).clamp(1.5, 3),
            ),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: isLoading
            ? SizedBox(
                height: r.spacing(24),
                width: r.spacing(24),
                child: CircularProgressIndicator(
                  strokeWidth: r.spacing(2.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: r.icon(22)),
                  SizedBox(width: r.spacing(10)),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: r.text(16),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: r.text(16),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
