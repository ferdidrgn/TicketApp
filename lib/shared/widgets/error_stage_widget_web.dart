import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    this.message,
    required this.onRetry,
  });

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFD4AF37),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'Hata',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD4AF37),
                    Color(0xFFF5E6A3),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Geri Dön',
                style: TextStyle(
                  color: Color(0xFF0a0a1a),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
