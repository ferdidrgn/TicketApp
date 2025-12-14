import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool isRequired;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool obscureText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    this.initialValue,
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
  }) : assert(
          initialValue == null || controller == null,
          'initialValue ve controller aynı anda kullanılamaz',
        );

  @override
  Widget build(final BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.red;
    const focusedBorderColor = Colors.purple;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: focusedBorderColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        obscureText: obscureText,
        validator: validator ??
            (final value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return '$label boş olamaz';
              }
              return null;
            },
      ),
    );
  }
}
