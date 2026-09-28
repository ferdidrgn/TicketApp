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

/// GİRİŞ EKRANI — MOBİL (5. TASARIM, KULLANICININ PAYLAŞTIĞI SOMUT GÖRSEL
/// REFERANSA GÖRE)
///
/// 3. deneme ("editoryal tipografi + kadro listesi", fotoğrafsız) kullanıcı
/// tarafından "berbat" olarak reddedildi — sadece `AuthWipeReveal` metin
/// açılışı beğenildi, o AYNEN korunuyor. Bu 5. tasarım kullanıcının
/// paylaştığı referans görselin (tek büyük yuvarlak köşeli afiş kartı: dev
/// başlık → tam-kanama editoryal fotoğraf → fotoğrafın alt kenarını
/// bindiren tek bir yüzen pill CTA) KOMPOZİSYONUNU alıyor — paletini değil
/// (uygulamanın koyu + kırmızı/altın kimliği `app_colors.dart`'tan asla
/// değişmedi).
///
/// Bu ekranın birden fazla aksiyonu var (Google + telefon) — referansın
/// "tek pill" kısıtını şöyle karşılıyor: TELEFONLA DEVAM ET tek yüzen
/// birincil pill (`AuthFloatingPillCTA`, uygulamanın asıl tercih ettiği
/// akış — bilet/koltuk telefon numarasına bağlı), Google ise kartın
/// ALTINDA, sessiz bir ikincil kontrol (`AuthGhostPillButton`) — 3.
/// denemenin numaralı "marquee" liste dili tekrar KULLANILMIYOR.
///
/// `phone_login_page_mobile.dart` bilerek aynı afiş-kartı DİLİNİ paylaşır
/// (tutarlılık) ama farklı bir fotoğraf + farklı bir aksiyon bloğu
/// kullanır — "varış" (bu ekran) ile "doğrulama" (o ekran) aynı anın
/// tekrarı değil.
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

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      isOverlayLoading: authMutation.isLoading,
      child: Stack(
        children: [
          const Positioned.fill(
            child: AuthStageBackdrop(
              glows: [
                Positioned(
                  top: -90,
                  right: -90,
                  child: AuthAmbientGlow(size: 320, tint: WebColors.primaryGold),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            // 🔥 Büyük tablet genişliğindeki bir cihazda (bu dosya native
            // mobil/tablet derlemesinde kullanılır) kart sonsuza kadar
            // yatayda GERİLMESİN diye — `ConstrainedBox` afiş kartını
            // referanstaki gibi kompakt/premium tutuyor, genişlik arttıkça
            // sadece ortalanıp etrafında zemin "nefes alıyor" (CLAUDE.md:
            // "mobile'ı büyütüp web diye sunma" — burada tam tersi,
            // mobil dosyanın kendisi geniş ekranda GERİLMİYOR).
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                FadeTransition(opacity: _fade(0.0), child: const _BrandRow()),
                const SizedBox(height: AppSpacing.lg),
                _PosterCard(fade: _fade, reveal: _reveal),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  child: Container(
                    margin: const EdgeInsets.only(
                        top: -(AuthFloatingPillCTA.height / 2)),
                    child: FadeTransition(
                      opacity: _fade(0.45),
                      child: AuthFloatingPillCTA(
                        label: l10n.loginPhoneButton,
                        icon: Icons.phone_iphone_rounded,
                        onTap: authMutation.isLoading
                            ? null
                            : () => NavigationHandler.goToPhoneLogin(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeTransition(
                  opacity: _fade(0.55),
                  child: Column(
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
                        onTap: authMutation.isLoading
                            ? null
                            : () => ref
                                .read(authMutationProvider.notifier)
                                .signInWithGoogle(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeTransition(
                  opacity: _fade(0.62),
                  child: Text(
                    l10n.loginTermsNotice,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Referans görseldeki tek, büyük yuvarlak köşeli afiş kartı: üstte
/// (WebColors.darkBlueSurface zemin üzerinde) dev başlık bandı, altında
/// tam-kanama fotoğraf bandı — İKİSİ de AYNI dış köşe silüetine
/// (`AppRadius.xl`) kırpılıyor, böylece TEK bir kart gibi okunuyor (kullanıcı
/// talimatı: "renk olarak renkler kalsın" — fotoğraf + koyu zemin, YENİ hex
/// yok).
class _PosterCard extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final Animation<double> Function(double start, double end) reveal;

  const _PosterCard({required this.fade, required this.reveal});

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
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                    AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.5,
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
                          fontSize: 40,
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
                          fontSize: 13.5,
                          height: 1.5,
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
                aspectRatio: 0.9,
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
