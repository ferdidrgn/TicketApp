import 'package:flutter/material.dart';

/// Yönlendirme mantığı (go_router) içermeyen, sadece görsel Splash tasarımı.
/// Bu widget'ı veri yüklenirken "Loading Indicator" yerine kullanacağız.
class SplashPage extends StatefulWidget {
  final String? loadingMessage;

  const SplashPage({super.key, this.loadingMessage});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
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
  Widget build(final BuildContext context) {
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
                    errorBuilder:
                        (final context, final error, final stackTrace) {
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

            SizedBox(height: isMobile ? 40 : 60),

            // Alt başlık
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Sahnede hayat, perdede hikaye\nHer oyun bir yolculuk, her sahne bir keşif',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFF5E6D3).withOpacity(0.9),
                  letterSpacing: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: isMobile ? 12 : 16),

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
