import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 🎭 Giriş koreografisi — perde açılışı hissi: logo önce büyüyerek/
  // parlayarak belirir, ardından başlık ve alt metin kademeli olarak
  // sahneye çıkar. Native splash (flutter_native_splash, uygulama
  // motoru başlamadan önceki statik ekran) burada BİTER, bu widget onun
  // yerini yumuşak bir devamlılıkla alır — sert bir kesim yerine.
  late AnimationController _entranceController;
  late Animation<double> _logoEntrance;
  late Animation<double> _titleEntrance;
  late Animation<double> _subtitleEntrance;

  @override
  void initState() {
    super.initState();
    // Hafif bir nefes alma/nabız efekti ekleyelim ki donmuş gibi görünmesin
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: AppMotion.symmetric),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _logoEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _titleEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _subtitleEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
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
            colors: [
              WebColors.veryDarkBlue,
              WebColors.darkBlueBackground,
              WebColors.darkBlueAccent,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo — giriş: küçük+saydamdan gelip hafif "fazla büyüyüp"
            // yerine oturuyor (easeOutBack), sonra sürekli nabız efekti
            // devralıyor. Yeni ikon zaten kendi koyu lacivert köşeli-kare
            // zeminiyle geliyor — ClipOval yerine kendi köşe diliyle
            // (AppRadius.asymLg) uyumlu yumuşak köşeli bir çerçeve.
            AnimatedBuilder(
              animation: Listenable.merge([_logoEntrance, _pulseAnimation]),
              builder: (final context, final child) {
                final entrance = _logoEntrance.value.clamp(0.0, 1.0);
                return Opacity(
                  opacity: entrance,
                  child: Transform.scale(
                    scale: (0.6 + 0.4 * entrance) * _pulseAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: isMobile ? 128 : 172,
                height: isMobile ? 128 : 172,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.asymLg,
                  boxShadow: AppShadows.level5(WebColors.primaryGold),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.asymLg,
                  child: Image.asset(
                    'assets/images/app_icon_master.png',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (final context, final error, final stackTrace) {
                      return const Icon(
                        Icons.theater_comedy,
                        size: 80,
                        color: WebColors.primaryGold,
                      );
                    },
                  ),
                ),
              ),
            ),

            SizedBox(height: isMobile ? AppSpacing.huge : 60),

            // Başlık — logodan hafif gecikmeli, aşağıdan belirerek gelir.
            AnimatedBuilder(
              animation: _titleEntrance,
              builder: (final context, final child) {
                final t = _titleEntrance.value.clamp(0.0, 1.0);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 18),
                    child: child,
                  ),
                );
              },
              child: Text(
                'TiyatRol',
                style: TextStyle(
                  fontSize: isMobile ? 40 : 56,
                  fontWeight: FontWeight.w700,
                  color: WebColors.primaryGold,
                  letterSpacing: 3,
                ),
              ),
            ),

            SizedBox(height: isMobile ? AppSpacing.huge : 60),

            // Alt başlık — en son beliren katman.
            AnimatedBuilder(
              animation: _subtitleEntrance,
              builder: (final context, final child) =>
                  Opacity(opacity: _subtitleEntrance.value.clamp(0.0, 1.0), child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: WebColors.primaryGold.withOpacity(0.3),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: WebColors.primaryGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Sahnede hayat, perdede hikaye\nHer oyun bir yolculuk, her sahne bir keşif',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w400,
                    color: WebColors.lightWhite.withOpacity(0.9),
                    letterSpacing: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                  backgroundColor: WebColors.darkBlueSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
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
                color: WebColors.primaryGold.withOpacity(0.8),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
