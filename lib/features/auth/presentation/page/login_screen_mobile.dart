import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../providers/auth_mutation_provider.dart';
import '../widgets/auth_atmosphere.dart';

/// GİRİŞ EKRANI — MOBİL (3. TASARIM, KULLANICININ AÇIK İSTEĞİ ÜZERİNE
/// KÖKTEN FARKLI)
///
/// Önceki iki deneme de aynı iskeleti tekrarlıyordu: tam ekran/panel
/// fotoğraf + üzerine bindirilmiş ya da altına oturan buton grubu. Bu
/// üçüncü tasarım o iskeleti TAMAMEN terk ediyor — hiç fotoğraf YOK.
/// Araştırmanın işaret ettiği yön (2025/2026 login trendleri: minimalizm,
/// pasif ışık/derinlik, sadece geri bildirime hizmet eden mikro-
/// etkileşimler — "kart üstüne kart" login şablonlarının tam tersi) ve
/// kullanıcının kendi talebi ("bambaşka, devrimsel") ile örtüşen bir
/// EDİTORYAL TİPOGRAFİ + TİYATRO PROGRAMI dili:
///   - Zemin: düz gradyan + TEK bir nefes alan spot ışığı (`AuthAmbientGlow`)
///   - Perde açılışıyla AYNI teknikle (bkz. `AuthWipeReveal`) soldan sağa
///     açılan dev bir başlık — kart/form kutusu değil, afiş tipografisi.
///   - Giriş yöntemleri bir "kadro listesi" gibi numaralı, alt çizgili
///     satırlar (`AuthMarqueeRow`) — pill buton/kart YOK.
/// `phone_login_page_mobile.dart` bilerek FARKLI bir görsel motif kullanır
/// (porthole fotoğraf + adım rozeti) — "varış" (bu ekran) ile "doğrulama"
/// (o ekran) aynı kalıbın tekrarı değil, iki ayrı an.
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

  Animation<double> _reveal(final double start, final double end) =>
      CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, end, curve: AppMotion.dramatic),
      );

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

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
      child: Stack(
        children: [
          const Positioned.fill(child: _StageBackdrop()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(opacity: _fade(0.0), child: const _BrandRow()),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _fade(0.05),
                  child: const Text(
                    'PERDE KALKMADAN ÖNCE',
                    style: TextStyle(
                      color: WebColors.primaryGoldLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthWipeReveal(
                  reveal: _reveal(0.08, 0.6),
                  child: Text(
                    'SAHNEYE\nADIM AT',
                    style: GoogleFonts.playfairDisplay(
                      color: WebColors.whiteText,
                      fontSize: 46,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeTransition(
                  opacity: _fade(0.35),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 340),
                    child: Text(
                      'Şehrin en seçkin oyunlarına, konserlerine ve '
                      'sahnelerine bir tık uzaktasın.',
                      style: TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: _fade(0.45),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'GİRİŞ YAP',
                        style: TextStyle(
                          color: WebColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AuthMarqueeRow(
                        index: '01',
                        icon: const GoogleLogo(size: 20),
                        label: 'Google ile Devam Et',
                        semanticLabel: 'Google ile giriş yap',
                        emphasize: true,
                        onTap: authMutation.isLoading
                            ? null
                            : () => ref
                                .read(authMutationProvider.notifier)
                                .signInWithGoogle(),
                      ),
                      AuthMarqueeRow(
                        index: '02',
                        icon: const Icon(
                          Icons.phone_iphone_rounded,
                          size: 18,
                          color: WebColors.primaryGoldLight,
                        ),
                        label: AppLocalizations.of(context)!.loginPhoneButton,
                        semanticLabel: 'Telefon numarasıyla giriş yap',
                        onTap: authMutation.isLoading
                            ? null
                            : () => NavigationHandler.goToPhoneLogin(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeTransition(
                  opacity: _fade(0.55),
                  child: Text(
                    AppLocalizations.of(context)!.loginTermsNotice,
                    style: TextStyle(
                      color: WebColors.textTertiary.withOpacity(0.85),
                      fontSize: 10,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Zemin: düz üç tonlu gradyan + TEK bir nefes alan spot ışığı (sağ üstte,
/// asimetrik). Fotoğraf yok — "Perde Açıldı" dilinin bu ekrandaki karşılığı
/// artık tipografi + ışık, gösterişli bir görsel panel değil.
class _StageBackdrop extends StatelessWidget {
  const _StageBackdrop();

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WebColors.veryDarkBlue,
                  WebColors.darkBlueBackground,
                  WebColors.darkBlueSurface,
                ],
              ),
            ),
          ),
          const Positioned(
            top: -70,
            right: -80,
            child: AuthAmbientGlow(size: 300, tint: WebColors.primaryGold),
          ),
        ],
      );
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(final BuildContext context) => Semantics(
        header: true,
        label: 'TİYATROL',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: WebColors.primaryGold.withOpacity(0.85),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.theater_comedy_rounded,
                size: 15,
                color: WebColors.primaryGoldLight,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'TİYATROL',
              style: GoogleFonts.playfairDisplay(
                color: WebColors.whiteText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      );
}
