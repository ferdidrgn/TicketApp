// ═══════════════════════════════════════════════════════
// 404 ERROR PAGE
// ═══════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../shared/navigation/widgets/nav_handler.dart';

class NotFoundPage extends StatelessWidget {
  final String? errorPath;

  const NotFoundPage({super.key, this.errorPath});

  @override
  Widget build(final BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 80, color: Color(0xFFD4AF37)),
              const SizedBox(height: 20),
              const Text(
                '404 - Sayfa Bulunamadı',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              if (errorPath != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Yol: $errorPath',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black),
                onPressed: () => NavigationHandler.goToHome(context),
                child: const Text('Ana Sayfaya Dön'),
              )
            ],
          ),
        ),
      );
}
