import 'package:flutter/material.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/utils/responsive.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? errorText;
  final Function(String)? onChanged;
  final FocusNode? focusNode;

  // ADD
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.focusNode,

    // ADD
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        TextFormField(
          controller: controller,

          focusNode: focusNode,

          obscureText: obscureText,

          keyboardType: keyboardType,

          validator: validator,

          onChanged: onChanged,

          style: TextStyle(fontSize: r.text(16), color: AppColors.yellow900),

          decoration: InputDecoration(
            hintText: hintText,

            hintStyle: TextStyle(
              color: AppColors.gray300,
              fontSize: r.text(16),
            ),

            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: hasError ? AppColors.error : AppColors.gray550,
                  )
                : null,

            // ADD
            suffixIcon: suffixIcon,

            filled: true,

            fillColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.spacing(12)),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.spacing(12)),
              borderSide: hasError
                  ? const BorderSide(color: AppColors.error, width: 1)
                  : BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.spacing(12)),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.yellow800,
                width: r.spacing(2),
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.spacing(12)),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.spacing(12)),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),

            contentPadding: EdgeInsets.symmetric(
              horizontal: r.spacing(20),
              vertical: r.spacing(18),
            ),
          ),
        ),

        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: r.spacing(6), left: r.spacing(12)),

            child: Text(
              errorText!,

              style: TextStyle(color: AppColors.error, fontSize: r.text(12)),
            ),
          ),
      ],
    );
  }
}
