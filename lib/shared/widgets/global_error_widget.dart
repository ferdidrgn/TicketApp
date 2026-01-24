import 'package:flutter/material.dart';

class GlobalErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback onRetry;
  final bool isFullPage;

  const GlobalErrorWidget({
    super.key,
    this.title,
    this.message,
    required this.onRetry,
    this.isFullPage = true,
  });

  @override
  Widget build(final BuildContext context) {
    // Tasarımlarındaki ortak altın rengi
    const goldColor = Color(0xFFD4AF37);
    const darkBg = Color(0xFF0a0a1a);

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ErrorStateWidget'tan gelen büyük ikon tasarımı
            const Icon(
              Icons.theater_comedy, // Sanat temana uygun ikon
              size: 80,
              color: goldColor,
            ),
            const SizedBox(height: 24),
            Text(
              title ?? "Sahne Hazırlanamadı",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Mesaj stili ErrorStateWidget'tan
            Text(
              message ?? 'Işıklar ve dekorlar yüklenirken bir sorun oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            // Tasarımındaki o şık gradient buton
            _buildGoldButton(goldColor, darkBg),
          ],
        ),
      ),
    );

    // Eğer tam sayfaysa Scaffold içine sarar, değilse direkt içeriği döner
    return isFullPage
        ? Scaffold(backgroundColor: darkBg, body: content)
        : content;
  }

  Widget _buildGoldButton(final Color goldColor, final Color darkBg) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          // ErrorStateWidget'taki gradient
          gradient: LinearGradient(
            colors: [goldColor, const Color(0xFFF5E6A3)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: goldColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Text(
          'TEKRAR DENE',
          style: TextStyle(
            color: Color(0xFF0F0F0F),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
