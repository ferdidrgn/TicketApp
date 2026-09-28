import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../providers/auth_mutation_provider.dart';

/// GİRİŞ EKRANI — MOBİL
///
/// KOMPOZİSYON (önceki tasarımdan yapısal olarak FARKLI — sadece fotoğraf
/// değişikliği değil): tek bir sütunda fotoğrafın üzerine bindirilmiş
/// butonlar yerine, 2026 mobil UI araştırmasının doğruladığı "bottom
/// sheet auth" deseni — iki ayrı bölge:
///   - ÜST BÖLGE (atmosfer): tam ekran sahne fotoğrafı + marka rozeti +
///      başlık. Sadece anlatı, hiç aksiyon yok.
///   - ALT BÖLGE (aksiyon): fotoğrafın üzerinde YARI SAYDAM değil, DÜZ/
///      opak bir "sahne platformu" yüzeyi — parmağın zaten durduğu alt
///      üçte birlik "rahat erişim bölgesi"nde, yüksek kontrastlı, gerçek
///      bir yüzey üzerinde oturan butonlar (metnin fotoğrafla asla
///      yarışmadığı, okunabilirliğin garanti olduğu bir zemin).
/// Bu, `login_screen_web.dart`'ın sol/sağ ayrımının mobildeki karşılığı —
/// aynı widget'ın küçültülmüşü değil, üst/alt gerçek bir bölünme.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..forward();

  Animation<double> _fade(final double start) => CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, 1.0, curve: Curves.easeOut),
      );

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final authMutation = ref.watch(authMutationProvider);

    ref.listen<AsyncValue<void>>(
      authMutationProvider,
      (final previous, final next) {
        next.whenOrNull(
          error: (final error, final stack) =>
              _showSnackBar(context, error.toString(), isError: true),
          data: (final _) {
            if (context.mounted) NavigationHandler.goToHome(context);
          },
        );
      },
    );

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      isOverlayLoading: authMutation.isLoading,
      // 🔥 DÜZELTME: `safeAreaTop: false` BasePageWrapper'ın KENDİ geri
      // butonunu/header'ını (TopHeaderWithBackButton) da aynı SafeArea'nın
      // İÇİNDE bırakıyordu — bu yüzden geri butonu ve (varsa) sağ üst ikon
      // durum çubuğunun/çentiğin ALTINA değil, TAM ÜSTÜNE/İÇİNE
      // çiziliyordu (ekran görüntüsündeki üst üste binme). Alttaki
      // `SafeArea(bottom: false, ...)` zaten kendi top:true varsayılanıyla
      // iç içe güvenle çalışıyor (dıştaki SafeArea top inset'i tükettiği
      // için içteki sıfır ek boşluk ekler, çift boşluk OLUŞMAZ) — bu
      // yüzden burada `safeAreaTop`'u false'a zorlamaya hiç gerek yoktu.
      layoutConfig: const BasePageLayoutConfig(
        safeAreaBottom: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. ÜST BÖLGE: SAHNE FOTOĞRAFI (SADECE ATMOSFER) ---
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Kullanıcının kendi seçimi: profil sayfasının misafir
                // durumundaki aynı "sahne/konser atmosferi" fotoğrafı
                // (bkz. profile_page.dart _stageBackdropUrl) — hem mobil
                // hem web login/telefon-login ekranlarında tutarlılık
                // için burada da kullanılıyor.
                const Image(
                  image: NetworkImage(
                      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1800&q=85'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                // Vinyet: üstte hafif (marka rozeti okunsun), altta güçlü —
                // alttaki opak platforma yumuşak bir dikişle bağlanıyor.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        WebColors.veryDarkBlue.withOpacity(0.35),
                        Colors.transparent,
                        WebColors.darkBlueSurface.withOpacity(0.55),
                        WebColors.darkBlueSurface,
                      ],
                      stops: const [0.0, 0.35, 0.85, 1.0],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                            opacity: _fade(0.0), child: const _TheaterBadge()),
                        const Spacer(),
                        FadeTransition(
                          opacity: _fade(0.1),
                          child: SlideTransition(
                            position: _fade(0.1).drive(Tween(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero)),
                            child: Text(
                              'Perde Açılıyor,\nYerin Sizi Bekliyor.',
                              style: GoogleFonts.playfairDisplay(
                                color: WebColors.whiteText,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                shadows: [
                                  Shadow(
                                    color:
                                        WebColors.veryDarkBlue.withOpacity(0.6),
                                    offset: const Offset(0, 3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. ALT BÖLGE: SAHNE PLATFORMU (AKSİYON — DÜZ ZEMİN) ---
          FadeTransition(
            opacity: _fade(0.2),
            child: SlideTransition(
              position: _fade(0.2)
                  .drive(Tween(begin: const Offset(0, 0.1), end: Offset.zero)),
              child: Container(
                decoration: const BoxDecoration(
                  color: WebColors.darkBlueSurface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                        AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Şehrin en seçkin oyunlarına, konserlerine ve '
                          'sahnelerine anında kapı arala.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: WebColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _ArtisticGoogleButton(
                          onTap: () => _handleGoogleSignIn(ref),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: WebColors.darkBlueAccent,
                                    height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              child: Text(
                                'VEYA',
                                style: TextStyle(
                                  color: WebColors.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: WebColors.darkBlueAccent,
                                    height: 1)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ArtisticPhoneButton(
                          label: AppLocalizations.of(context)!.loginPhoneButton,
                          onTap: () =>
                              NavigationHandler.goToPhoneLogin(context),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _FinePrint(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn(final WidgetRef ref) async =>
      ref.read(authMutationProvider.notifier).signInWithGoogle();

  void _showSnackBar(final BuildContext context, final String msg,
      {final bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Tiyatro Rozeti Bileşeni
class _TheaterBadge extends StatelessWidget {
  const _TheaterBadge();

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      label: 'Tiyatro ve sahne sanatları platformu',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.55),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: WebColors.primaryGold.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: AppShadows.level1(WebColors.veryDarkBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.theater_comedy_rounded,
              color: WebColors.primaryGoldLight,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Tiyatro & Sahne Sanatları',
              style: TextStyle(
                color: WebColors.whiteText.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google Giriş Butonu — birincil CTA (araştırmanın doğruladığı hiyerarşi:
/// tüketici uygulamalarında sosyal giriş birincil, diğerleri altında/
/// ikincil). Google'ın kendi marka kurallarıyla çakışmasın diye simetrik
/// köşe (asimetrik "sahne köşesi" imzası BİLEREK burada değil).
class _ArtisticGoogleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ArtisticGoogleButton({required this.onTap});

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      button: true,
      label: 'Google ile giriş yap',
      child: Material(
        color: WebColors.whiteText,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.level2(WebColors.veryDarkBlue),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            splashColor: Colors.grey.withOpacity(0.15),
            highlightColor: Colors.grey.withOpacity(0.1),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleLogo(size: 22),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    'Google ile Sahneye Adım At',
                    style: TextStyle(
                      color: Color(0xFF1F1F1F),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Telefon Giriş Butonu — ikincil CTA, ekranın imza asimetrik "sahne
/// köşesi" (`AppRadius.asymLg`) burada, düz platform zemininde TEK vurgu
/// noktası olarak kullanılıyor.
class _ArtisticPhoneButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ArtisticPhoneButton({required this.label, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      button: true,
      label: 'Telefon numarasıyla giriş yap',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.asymLg,
        child: Ink(
          decoration: BoxDecoration(
            color: WebColors.darkBlueBackground,
            borderRadius: AppRadius.asymLg,
            border: Border.all(
              color: WebColors.darkBlueAccent,
              width: 1.4,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.asymLg,
            splashColor: WebColors.primaryGold.withOpacity(0.1),
            highlightColor: WebColors.primaryGold.withOpacity(0.05),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: WebColors.primaryGold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: WebColors.primaryGoldLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: const TextStyle(
                      color: WebColors.whiteText,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinePrint extends StatelessWidget {
  const _FinePrint();

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.loginTermsNotice,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: WebColors.textTertiary.withOpacity(0.85),
          letterSpacing: 0.5,
          fontSize: 10,
          height: 1.4,
        ),
      ),
    );
  }
}
