import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Koyu, neon çerçeveli tek satırlık giriş kutusu.
class NeonField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final IconData? icon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const NeonField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.icon,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyanNeon.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.cyanNeon.withOpacity(0.8)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              onChanged: onChanged,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              cursorColor: AppColors.cyanNeon,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textGray, fontSize: 13),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}
