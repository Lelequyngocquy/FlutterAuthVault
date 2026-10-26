import 'package:flutter/material.dart';
import '../../../common/constants/colors.dart';
import '../../../common/constants/dimen.dart';
import 'text.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.errorText,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.eyebrow(label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: UIColors.canvasSoft,
            borderRadius: BorderRadius.circular(Dimen.radiusSm),
            border: Border.all(
              color: errorText != null ? UIColors.error : UIColors.hairline,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              color: UIColors.ink,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: UIColors.mute, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          AppText.regular(errorText!, color: UIColors.error, fontSize: 12),
        ],
      ],
    );
  }
}
