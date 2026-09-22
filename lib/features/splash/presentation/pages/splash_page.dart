import 'package:flutter/material.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';

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
      CurvedAnimation(parent: _controller, curve: AppMotion.symmetric),
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
            colors: [Color(0xFF0F2318), Color(0xFF1B3A26), Color(0xFF24402C)],
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
                  boxShadow: AppShadows.level5(const Color(0xFFE85C3F)),
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
                        color: Color(0xFFE85C3F),
                      );
                    },
                  ),
                ),
              ),
            ),

            SizedBox(height: isMobile ? AppSpacing.huge : 60),

            // Başlık
            Text(
              'TiyatRol',
              style: TextStyle(
                fontSize: isMobile ? 40 : 56,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE85C3F),
                letterSpacing: 3,
              ),
            ),

            SizedBox(height: isMobile ? AppSpacing.huge : 60),

            // Alt başlık
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE85C3F).withOpacity(0.3),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: const Color(0xFFE85C3F).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Sahnede hayat, perdede hikaye\nHer oyun bir yolculuk, her sahne bir keşif',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFEAE1C8).withOpacity(0.9),
                  letterSpacing: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

            // Loading Bar (Indeterminate)
            Semantics(
              label: widget.loadingMessage ?? 'Sahne hazırlanıyor',
              liveRegion: true,
              child: SizedBox(
                width: isMobile ? 200 : 300,
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFF1B3A26),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE85C3F)),
                  minHeight: 2,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Dinamik Mesaj
            Text(
              widget.loadingMessage ?? 'Sahne hazırlanıyor...',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w300,
                color: const Color(0xFFE85C3F).withOpacity(0.8),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
