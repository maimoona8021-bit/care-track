import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;

  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;

  final IconData? prefixIcon;
  final Widget? suffixIcon;

  final String? Function(String?)? validator;

  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.fieldLabel,
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          validator: validator,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMedium,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
              prefixIcon,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}