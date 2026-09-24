import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';

class OnboardingContainer extends ConsumerStatefulWidget {
  const OnboardingContainer({super.key});

  @override
  ConsumerState<OnboardingContainer> createState() =>
      _OnboardingContainerState();
}

class _OnboardingContainerState extends ConsumerState<OnboardingContainer>
    with SingleTickerProviderStateMixin {
  // 🎉 Onboarding tamamlandığında kısa bir kutlama patlaması için.
  late final ConfettiController _confettiController;

  // 🎬 Girişte içeriğin (başlık/alt başlık/buton) sahneye deliberate bir
  // şekilde süzülerek gelmesi için — show_detail sayfasındaki reveal
  // animasyonuyla aynı hareket dilini (AppMotion) kullanır.
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: AppMotion.slow);

    _entranceController =
        AnimationController(duration: AppMotion.slow, vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: AppMotion.standard),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: AppMotion.standard),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // 🎉 Onboarding'in tamamlandığı TEK an burası: kullanıcı "KEŞFETMEYE
  // BAŞLA"ya bastığında konfeti patlatılır, kısa bir süre görünür kalması
  // için beklenir ve ardından ana sayfaya geçilir.
  Future<void> _completeOnboarding(final BuildContext context) async {
    _confettiController.play();
    await Future.delayed(AppMotion.slow);
    if (!context.mounted) return;
    NavigationHandler.goToHome(context);
  }

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      showBackButton: false, // Onboarding'de geri butonu olmaz
      showFab: false,
      layoutConfig: const BasePageLayoutConfig(
        safeAreaTop: false,
        safeAreaBottom: false,
        extendBody: true,
      ),
      child: Stack(
        children: [
          // 1. TAM EKRAN ARKA PLAN (Görsel Derinlik)
          _buildHeroBackground(),

          // 2. GRADIENT OVERLAY (Yazıların okunması için)
          _buildGradientOverlay(),

          // 3. İÇERİK (Responsive ve Ortalı)
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 500 : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl, vertical: AppSpacing.huge),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(context),
                          const SizedBox(height: AppSpacing.lg),
                          _buildSubtitle(context),
                          const SizedBox(height: AppSpacing.massive),
                          _buildStartButton(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. KUTLAMA KONFETİSİ (Onboarding tamamlanma anı)
          _buildConfetti(context),
        ],
      ),
    );
  }

  // 🔥 DÜZELTME: `assets/images/onboarding_hero.jpg` HİÇ VAR OLMAYAN bir
  // dosyaydı ("Kendi görselinle değiştir abi" yorumu bunun bilinçli bir
  // yer tutucu olduğunu gösteriyor) — bu yüzden uygulamanın ilk açılış
  // ekranı her zaman kırık/boş bir görselle render ediliyordu. `pubspec.
  // yaml`'da zaten deklare edilmiş ama kodda HİÇBİR YERDE kullanılmayan
  // gerçek bir tiyatro fotoğrafı (`main_theatre.png`) vardı — yeni bir
  // görsel icat etmek yerine onu bağladık.
  Widget _buildHeroBackground() => Positioned.fill(
        child: Image.asset(
          'assets/images/main_theatre.png',
          fit: BoxFit.cover,
        ),
      );

  Widget _buildGradientOverlay() => Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
      );

  Widget _buildTitle(final BuildContext context) => const Text(
        'SANATIN\nKAPILARI\nAÇILIYOR',
        style: TextStyle(
          fontSize: 42,
          height: 0.9,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -1.5,
        ),
      );

  Widget _buildSubtitle(final BuildContext context) => Opacity(
        opacity: 0.8,
        child: Text(
          'Şehrin en iyi sahneleri, küratör seçkileri ve benzersiz deneyimler koleksiyonunda seni bekliyor.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            height: 1.5,
          ),
        ),
      );

  Widget _buildStartButton(final BuildContext context) => Semantics(
        button: true,
        label: 'Keşfetmeye başla',
        child: GestureDetector(
          onTap: () => _completeOnboarding(context),
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.colors.primary, context.colors.secondary],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.level3(context.colors.primary),
            ),
            child: const Center(
              child: Text(
                'KEŞFETMEYE BAŞLA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      );

  // 🎉 Konfeti, ekranın üst ortasından aşağı doğru kısa ve zarif bir patlama
  // yapar. Sayfanın Material tema renkleriyle (buton gradyanıyla aynı)
  // uyumlu olsun diye context.colors kullanılıyor.
  Widget _buildConfetti(final BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // aşağı doğru
            maxBlastForce: 10,
            minBlastForce: 4,
            emissionFrequency: 0.08,
            numberOfParticles: 16,
            gravity: 0.3,
            shouldLoop: false,
            colors: [
              context.colors.primary,
              context.colors.secondary,
              Colors.white,
            ],
          ),
        ),
      );
}
