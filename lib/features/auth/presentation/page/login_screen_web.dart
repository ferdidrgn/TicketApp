import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../providers/auth_mutation_provider.dart';
import '../widgets/auth_atmosphere.dart';

/// GİRİŞ EKRANI — MASAÜSTÜ/WEB (3. TASARIM, KULLANICININ AÇIK İSTEĞİ
/// ÜZERİNE KÖKTEN FARKLI)
///
/// KASITLI OLARAK `BasePageWrapper` KULLANMIYOR — `login_screen_web.dart`'ın
/// önceki iki sürümüyle AYNI gerekçe: bu wrapper mobil uygulama çatısı için,
/// kimlik doğrulama öncesi tam ekran bir an burada bir shell/top-nav'a
/// SARILMIYOR, o yüzden sayfa kendi geri tuşunu (`GlassmorphismBackButton`
/// — glass BURADA meşru: floating overlay control) sol üstte kendisi
/// sağlıyor.
///
/// ÖNCEKİ İKİ DENEME de "sol fotoğraf paneli / sağ form kartı" ikilisini
/// tekrarlıyordu. Bu sürüm o ikiliyi tamamen bırakıyor: sol tarafta dev,
/// asimetrik bir AFİŞ TİPOGRAFİSİ (fotoğraf YOK), sağ tarafta bir tiyatro
/// programı gibi numaralanmış "marquee" satırları — aralarında tek bir
/// ince altın çizgi (kural: her yerde border/kart değil, TEK bir çizgi).
/// ~900px altında (dar tarayıcı penceresi) aynı iki blok dikey akışa
/// döner — bu GERÇEK bir web-içi kırılma noktası, mobil dosyasının
/// büyütülmüş hali DEĞİL (mobil dosyası hiç fotoğraf kullanmıyor olsa da
/// bu ekranın kendi iç mantığı zaten fotoğrafsız; burada tekrarlanan
/// sadece AYNI web dosyasının kendi içindeki dar-pencere davranışı).
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

    return ColoredBox(
      color: WebColors.veryDarkBlue,
      child: Stack(
        children: [
          const Positioned.fill(child: _StageBackdrop()),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (final context, final constraints) {
                final bool split = constraints.maxWidth >= 900;
                final typography =
                    _TypographyPane(fade: _fade, reveal: _reveal);
                final actions = _ActionPane(
                  fade: _fade,
                  isLoading: authMutation.isLoading,
                  onGoogleTap: () => ref
                      .read(authMutationProvider.notifier)
                      .signInWithGoogle(),
                  onPhoneTap: () => NavigationHandler.goToPhoneLogin(context),
                );
                if (split) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: typography),
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(
                            vertical: AppSpacing.section),
                        color: WebColors.primaryGold.withOpacity(0.18),
                      ),
                      Expanded(flex: 5, child: actions),
                    ],
                  );
                }
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [typography, actions],
                  ),
                );
              },
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

/// Zemin: düz gradyan + TEK spot ışığı — sol üstte, afiş metninin arkasında
/// asimetrik bir vurgu olarak.
class _StageBackdrop extends StatelessWidget {
  const _StageBackdrop();

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  WebColors.veryDarkBlue,
                  WebColors.darkBlueBackground,
                  WebColors.darkBlueSurface,
                ],
              ),
            ),
          ),
          const Positioned(
            top: -140,
            left: -120,
            child: AuthAmbientGlow(size: 480, tint: WebColors.primaryGold),
          ),
        ],
      );
}

/// SOL BÖLGE — dev, sola hizalı afiş tipografisi. Fotoğraf yok, hiyerarşi
/// tamamen ölçek/ağırlık/perde-açılışı hareketi ile kuruluyor.
class _TypographyPane extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final Animation<double> Function(double start, double end) reveal;

  const _TypographyPane({required this.fade, required this.reveal});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.section,
            AppSpacing.section, AppSpacing.xxxl, AppSpacing.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
                  fontSize: 76,
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeTransition(
              opacity: fade(0.4),
              child: const ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 420),
                child: Text(
                  'Şehrin en seçkin oyunlarına, konserlerine ve '
                  'sahnelerine bir tık uzaktasın.',
                  style: TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 15.5,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// SAĞ BÖLGE — numaralı "marquee" satırları, dikeyde ortalanmış. Kural:
/// klavye tamamen kullanılabilir (`AuthMarqueeRow`'un `InkWell`'i Tab ile
/// odaklanır, Enter/Space ile tetiklenir).
class _ActionPane extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final bool isLoading;
  final VoidCallback onGoogleTap;
  final VoidCallback onPhoneTap;

  const _ActionPane({
    required this.fade,
    required this.isLoading,
    required this.onGoogleTap,
    required this.onPhoneTap,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl, vertical: AppSpacing.section),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: FadeTransition(
              opacity: fade(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GİRİŞ YAP',
                    style: TextStyle(
                      color: WebColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthMarqueeRow(
                    index: '01',
                    icon: const GoogleLogo(size: 20),
                    label: 'Google ile Devam Et',
                    semanticLabel: 'Google ile giriş yap',
                    emphasize: true,
                    onTap: isLoading ? null : onGoogleTap,
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
                    onTap: isLoading ? null : onPhoneTap,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppLocalizations.of(context)!.loginTermsNotice,
                    style: TextStyle(
                      color: WebColors.textTertiary.withOpacity(0.85),
                      fontSize: 10.5,
                      letterSpacing: 0.4,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            const SizedBox(width: 12),
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
