// ═══════════════════════════════════════════════════════════
// 404 ERROR PAGE - REFACTORED
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../shared/navigation/widgets/nav_handler.dart';
import '../../shared/widgets/button/back_button_glassmorphism.dart';
import '../common/extentions/app_context_ui_extension.dart';

class NotFoundPage extends StatelessWidget {
  final String? errorPath;

  const NotFoundPage({super.key, this.errorPath});

  @override
  Widget build(final BuildContext context) => Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // --- ANA İÇERİK ---
            Center(
              child: Padding(
                padding: context.pagePadding, // Responsive padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hata İkonu - Temanın ana rengiyle uyumlu
                    Icon(Icons.error_outline,
                        size: 80, color: context.primaryColor),
                    const SizedBox(height: 20),

                    Text('404 - Sayfa Bulunamadı',
                        style: context.textTheme.headlineMedium?.copyWith(
                            color: context.colors.onSurface,
                            // Tema uyumlu metin
                            fontWeight: FontWeight.bold)),

                    if (errorPath != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Yol: $errorPath',
                        style: context.textTheme.bodyMedium
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Ana Sayfaya Dön Butonu - Tema Renkleri
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: context.colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => NavigationHandler.goToHome(context),
                      child: const Text('Ana Sayfaya Dön',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            // --- MANUEL GERİ BUTONU ---
            // BaseWrapper yerine doğrudan Stack içinde en üste koyuyoruz
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: const GlassmorphismBackButton(),
            ),
          ],
        ),
      );
}
