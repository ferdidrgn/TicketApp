import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../providers/auth_mutation_provider.dart';
import '../widgets/auth_atmosphere.dart';

/// GİRİŞ EKRANI — MASAÜSTÜ/WEB (5. TASARIM, KULLANICININ PAYLAŞTIĞI SOMUT
/// GÖRSEL REFERANSA GÖRE)
///
/// KASITLI OLARAK `BasePageWrapper` KULLANMIYOR — `login_screen_web.dart`'ın
/// önceki sürümleriyle AYNI gerekçe: bu wrapper mobil uygulama çatısı için,
/// kimlik doğrulama öncesi tam ekran bir an burada bir shell/top-nav'a
/// SARILMIYOR, sayfa kendi geri tuşunu (`GlassmorphismBackButton` — glass
/// BURADA meşru: floating overlay control) sol üstte kendisi sağlıyor.
///
/// 3. deneme ("editoryal afiş tipografisi + numaralı marquee satırları",
/// fotoğrafsız) kullanıcı tarafından "berbat" reddedildi — sadece
/// `AuthWipeReveal` metin açılışı beğenildi, AYNEN korunuyor. Bu 5. tasarım
/// referans görselin kompozisyonunu (tek büyük yuvarlak köşeli afiş kartı →
/// dev başlık → tam-kanama fotoğraf → fotoğrafın alt kenarını bindiren tek
/// bir yüzen pill CTA) alıyor, paletini DEĞİL.
///
/// GERÇEK responsive kırılma noktaları — `home_page_web.dart`'ın kendi
/// `context.responsive`/`ResponsiveUtils` kullanım kuralıyla AYNI:
///   - Mobil-genişlikte tarayıcı (<768) ve TABLET (768-1024): afiş kartı
///     TEK sütun, dikeyde — ama tablette kart daha geniş/merkezî bir
///     maksimum genişlikte, tipografi biraz daha büyük (sadece mobili
///     büyütmek DEĞİL, kendi ölçeği var).
///   - GENİŞ MASAÜSTÜ (>=1024): kart ikiye ayrılıyor — solda saf tipografi
///     paneli (başlık+alt metin+ikincil Google aksiyonu), sağda SADECE
///     fotoğraf+yüzen pill CTA'dan oluşan uzun bir afiş paneli. Bu tablet
///     sütununun aynı büyütülmüş hali DEĞİL — kompozisyon gerçekten
///     ikiye bölünüyor (`home_page_web.dart`'taki hero solu/sağı ayrımıyla
///     aynı dil).
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

    final l10n = AppLocalizations.of(context)!;
    final bool isDesktop = ResponsiveUtils.isDesktop(context);
    final bool isTablet = ResponsiveUtils.isTablet(context);

    final actions = _LoginActions(
      isLoading: authMutation.isLoading,
      onPhoneTap: () => NavigationHandler.goToPhoneLogin(context),
      onGoogleTap: () =>
          ref.read(authMutationProvider.notifier).signInWithGoogle(),
    );

    return ColoredBox(
      color: WebColors.veryDarkBlue,
      child: Stack(
        children: [
          const Positioned.fill(
            child: AuthStageBackdrop(
              glows: [
                Positioned(
                  top: -140,
                  right: -120,
                  child: AuthAmbientGlow(size: 460, tint: WebColors.primaryGold),
                ),
                Positioned(
                  bottom: -160,
                  left: -140,
                  child: AuthAmbientGlow(
                      size: 380, tint: WebColors.secondaryAccent),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(
                    mobile: AppSpacing.xl,
                    tablet: AppSpacing.xxxl,
                    desktop: AppSpacing.section),
                vertical: AppSpacing.section,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1080 : (isTablet ? 620 : 480)),
                  child: isDesktop
                      ? _WideSplit(
                          fade: _fade,
                          reveal: _reveal,
                          l10n: l10n,
                          actions: actions,
                        )
                      : _StackedPoster(
                          fade: _fade,
                          reveal: _reveal,
                          l10n: l10n,
                          actions: actions,
                          isTablet: isTablet,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xl,
            left: AppSpacing.xl,
            child: GlassmorphismBackButton(
              onPressed: () => NavigationHandler.smartGoBack(context),
              size: 44,
            ),
          ),
          if (authMutation.isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: WebColors.veryDarkBlue.withOpacity(0.55),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: WebColors.primaryGoldLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Telefon (birincil, yüzen pill) + Google (ikincil, sessiz ghost-pill)
/// aksiyon çiftini SADECE bir kere tanımlayan, dar/tablet/geniş üç
/// yerleşimin de paylaştığı küçük veri taşıyıcı.
class _LoginActions {
  final bool isLoading;
  final VoidCallback onPhoneTap;
  final VoidCallback onGoogleTap;

  const _LoginActions({
    required this.isLoading,
    required this.onPhoneTap,
    required this.onGoogleTap,
  });
}

/// DAR TARAYICI / TABLET — tek sütun, tek afiş kartı. Tablette (`isTablet`)
/// sadece mobilin büyütülmüş hali DEĞİL: kart daha geniş bir maksimum
/// genişlikte merkezî duruyor, tipografi bir kademe büyüyor.
class _StackedPoster extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final Animation<double> Function(double start, double end) reveal;
  final AppLocalizations l10n;
  final _LoginActions actions;
  final bool isTablet;

  const _StackedPoster({
    required this.fade,
    required this.reveal,
    required this.l10n,
    required this.actions,
    required this.isTablet,
  });

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeTransition(opacity: fade(0.0), child: const _BrandRow()),
          const SizedBox(height: AppSpacing.xl),
          _PosterCard(
            fade: fade,
            reveal: reveal,
            headlineSize: isTablet ? 48 : 40,
          ),
          Transform.translate(
            offset: const Offset(0, -(AuthFloatingPillCTA.height / 2)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: FadeTransition(
                opacity: fade(0.45),
                child: AuthFloatingPillCTA(
                  label: l10n.loginPhoneButton,
                  icon: Icons.phone_iphone_rounded,
                  onTap: actions.isLoading ? null : actions.onPhoneTap,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FadeTransition(
            opacity: fade(0.55),
            child: Center(
              child: _GoogleSecondaryAction(l10n: l10n, actions: actions),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeTransition(
            opacity: fade(0.62),
            child: Text(
              l10n.loginTermsNotice,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: WebColors.textTertiary.withOpacity(0.85),
                fontSize: 10.5,
                letterSpacing: 0.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
}

/// GENİŞ MASAÜSTÜ — kompozisyon ikiye ayrılıyor: solda saf tipografi +
/// ikincil aksiyon, sağda SADECE fotoğraf + yüzen pill'den oluşan uzun bir
/// afiş paneli (`home_page_web.dart`'taki hero sol/sağ ayrımıyla aynı dil).
class _WideSplit extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final Animation<double> Function(double start, double end) reveal;
  final AppLocalizations l10n;
  final _LoginActions actions;

  const _WideSplit({
    required this.fade,
    required this.reveal,
    required this.l10n,
    required this.actions,
  });

  @override
  Widget build(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(opacity: fade(0.0), child: const _BrandRow()),
                const SizedBox(height: AppSpacing.massive),
                FadeTransition(
                  opacity: fade(0.05),
                  child: const Text(
                    'PERDE KALKMADAN ÖNCE',
                    style: TextStyle(
                      color: WebColors.primaryGoldLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AuthWipeReveal(
                  reveal: reveal(0.1, 0.6),
                  child: Text(
                    'SAHNEYE\nADIM AT',
                    style: GoogleFonts.playfairDisplay(
                      color: WebColors.whiteText,
                      fontSize: 68,
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeTransition(
                  opacity: fade(0.4),
                  child: const ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 380),
                    child: Text(
                      'Şehrin en seçkin oyunlarına, konserlerine ve '
                      'sahnelerine bir tık uzaktasın.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 15.5,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.massive),
                FadeTransition(
                  opacity: fade(0.5),
                  child: _GoogleSecondaryAction(l10n: l10n, actions: actions),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeTransition(
                  opacity: fade(0.6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(
                      l10n.loginTermsNotice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: WebColors.textTertiary.withOpacity(0.85),
                        fontSize: 10.5,
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            flex: 4,
            child: FadeTransition(
              opacity: fade(0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: const AspectRatio(
                      aspectRatio: 0.72,
                      child: AuthHeroPoster(imageUrl: _PosterCard._imageUrl),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -(AuthFloatingPillCTA.height / 2)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: AuthFloatingPillCTA(
                        label: l10n.loginPhoneButton,
                        icon: Icons.phone_iphone_rounded,
                        onTap: actions.isLoading ? null : actions.onPhoneTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _GoogleSecondaryAction extends StatelessWidget {
  final AppLocalizations l10n;
  final _LoginActions actions;

  const _GoogleSecondaryAction({required this.l10n, required this.actions});

  @override
  Widget build(final BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'YA DA',
            style: TextStyle(
              color: WebColors.textTertiary.withOpacity(0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AuthGhostPillButton(
            label: l10n.loginGoogleButton,
            icon: const GoogleLogo(size: 18),
            semanticLabel: 'Google ile giriş yap',
            onTap: actions.isLoading ? null : actions.onGoogleTap,
          ),
        ],
      );
}

/// Referans görseldeki tek, büyük yuvarlak köşeli afiş kartı — dar/tablet
/// yerleşiminde kullanılan TEK-sütun sürümü (başlık bandı + fotoğraf bandı
/// AYNI dış köşe silüetine kırpılıyor).
class _PosterCard extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final Animation<double> Function(double start, double end) reveal;
  final double headlineSize;

  const _PosterCard({
    required this.fade,
    required this.reveal,
    required this.headlineSize,
  });

  static const String _imageUrl =
      'https://images.unsplash.com/photo-1503095396549-807759245b35'
      '?auto=format&fit=crop&w=1600&q=85';

  @override
  Widget build(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColoredBox(
              color: WebColors.darkBlueSurface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                    AppSpacing.xxxl, AppSpacing.xxl, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: fade(0.05),
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
                    const SizedBox(height: AppSpacing.xs),
                    AuthWipeReveal(
                      reveal: reveal(0.1, 0.6),
                      child: Text(
                        'SAHNEYE\nADIM AT',
                        style: GoogleFonts.playfairDisplay(
                          color: WebColors.whiteText,
                          fontSize: headlineSize,
                          fontWeight: FontWeight.w700,
                          height: 1.04,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FadeTransition(
                      opacity: fade(0.35),
                      child: const Text(
                        'Şehrin en seçkin oyunlarına, konserlerine ve '
                        'sahnelerine bir tık uzaktasın.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: WebColors.textSecondary,
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FadeTransition(
              opacity: fade(0.12),
              child: const AspectRatio(
                aspectRatio: 1.15,
                child: AuthHeroPoster(imageUrl: _imageUrl),
              ),
            ),
          ],
        ),
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
              width: 34,
              height: 34,
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
                size: 16,
                color: WebColors.primaryGoldLight,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'TİYATROL',
              style: GoogleFonts.playfairDisplay(
                color: WebColors.whiteText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      );
}
