import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller; // Patron bu!
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool isRequired;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool obscureText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.isRequired = true,
    this.validator,
    this.maxLines = 1,
    this.obscureText = false,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
  });

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;
    final borderColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black12;
    final focusedColor = context.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        // Artık sadece controller var, kafa karışıklığı bitti.
        inputFormatters: inputFormatters,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          // Modern Border Tasarımı (Bilet sayfanla uyumlu)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: focusedColor, width: 1.5),
          ),
          filled: true,
          fillColor:
              isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        ),
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        obscureText: obscureText,
        validator: validator ??
            (final value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return '$label alanı boş bırakılamaz';
              }
              return null;
            },
      ),
    );
  }
}
