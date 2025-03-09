import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final bool isRequired;

  const CustomTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.isRequired = true, // Varsayılan olarak zorunlu
  });

  @override
  Widget build(final BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.red; // Tıklanmadığında renk
    const focusedBorderColor = Colors.purple; // Tıklandığında renk

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Theme.of(context).colorScheme.background,
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator: (final value) {
          // Eğer alan zorunluysa ve değer boşsa, hata döndür
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Bu alan boş olamaz';
          }
          return null; // Boşsa ve zorunlu değilse, doğrulama hatası döndürme
        },
      ),
    );
  }
}
