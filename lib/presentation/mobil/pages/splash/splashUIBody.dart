import 'package:flutter/material.dart';

/// Yönlendirme mantığı (go_router) içermeyen, sadece görsel Splash tasarımı.
/// Bu widget'ı veri yüklenirken "Loading Indicator" yerine kullanacağız.
class SplashUIBody extends StatefulWidget {
  final String? loadingMessage;

  const SplashUIBody({super.key, this.loadingMessage});

  @override
  State<SplashUIBody> createState() => _SplashUIBodyState();
}

class _SplashUIBodyState extends State<SplashUIBody> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Hafif bir nefes alma/nabız efekti ekleyelim ki donmuş gibi görünmesin
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ve Nabız Animasyonu
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: isMobile ? 120 : 160,
                height: isMobile ? 120 : 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/tiyatrol_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.theater_comedy,
                        size: 80,
                        color: Color(0xFFD4AF37),
                      );
                    },
                  ),
                ),
              ),
            ),

            SizedBox(height: isMobile ? 40 : 60),

            // Başlık
            Text(
              'TiyatRol',
              style: TextStyle(
                fontSize: isMobile ? 40 : 56,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD4AF37),
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 24),

            // Loading Bar (Indeterminate)
            SizedBox(
              width: isMobile ? 200 : 300,
              child: const LinearProgressIndicator(
                backgroundColor: Color(0xFF1a1a2e),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                minHeight: 2,
              ),
            ),

            const SizedBox(height: 16),

            // Dinamik Mesaj
            Text(
              widget.loadingMessage ?? 'Sahne hazırlanıyor...',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w300,
                color: const Color(0xFFD4AF37).withOpacity(0.8),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}