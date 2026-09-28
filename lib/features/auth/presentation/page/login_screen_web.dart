import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/app_motion.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_shadows.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../providers/auth_mutation_provider.dart';

/// GİRİŞ EKRANI — MASAÜSTÜ/WEB
///
/// KASITLI OLARAK `BasePageWrapper` KULLANMIYOR (`home_page_web.dart` ile
/// aynı gerekçe): o wrapper mobil uygulama çatısı (geri tuşu başlığı,
/// pull-to-refresh, parçacık arka planı) için — bir web sayfasını "Android
/// uygulaması gibi" gösterirdi. `/login` ve `/phone-login` rotaları
/// `app_router.dart`'ta bir shell/top-nav içine SARILMIYOR (kimlik
/// doğrulama öncesi, tam ekran bir an), o yüzden bu sayfa kendi geri
/// tuşunu (`GlassmorphismBackButton` — glass BURADA meşru: floating
/// overlay control) sol üstte kendisi sağlıyor.
///
/// Kompozisyon: gerçek bir "split-screen" — sol sabit panel tiyatro
/// fotoğrafı + marka + editoryal alıntı, sağ panel form kartı. Mobildeki
/// tek sütunun ortada daha çok boşlukla büyütülmüş hali DEĞİL: iki panel
/// birbirinden farklı görevler taşıyor (atmosfer vs. aksiyon), gerçek
/// hover durumları var, Tab/Enter ile tamamen klavyeyle kullanılabilir
/// (butonlar `InkWell` — odaklanabilir + Enter/Space ile tetiklenir).
///
/// Dar bir web penceresinde (telefon tarayıcısı) de açılabileceği için
/// `LayoutBuilder` ile GERÇEK bir iç kırılma noktası var: ~900px altında
/// sol panel üstte kısalan bir şerde döner, form altta — "aynı widget'ı
/// büyütüp mobil diye sunma" kuralının web-web ölçeğindeki karşılığı.
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
          Positioned.fill(
            child: LayoutBuilder(
              builder: (final context, final constraints) {
                final bool split = constraints.maxWidth >= 900;
                if (split) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _StagePanel(fade: _fade),
                      ),
                      Expanded(
                        flex: 4,
                        child: _FormPanel(
                          fade: _fade,
                          isLoading: authMutation.isLoading,
                          onGoogleTap: () =>
                              ref.read(authMutationProvider.notifier)
                                  .signInWithGoogle(),
                          onPhoneTap: () =>
                              NavigationHandler.goToPhoneLogin(context),
                        ),
                      ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * 0.42,
                        child: _StagePanel(fade: _fade, compact: true),
                      ),
                      _FormPanel(
                        fade: _fade,
                        isLoading: authMutation.isLoading,
                        onGoogleTap: () =>
                            ref.read(authMutationProvider.notifier)
                                .signInWithGoogle(),
                        onPhoneTap: () =>
                            NavigationHandler.goToPhoneLogin(context),
                      ),
                    ],
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

/// SOL PANEL — sahne fotoğrafı, marka, editoryal alıntı. `home_page_web.dart`
/// `_HeroBackdropPhoto`si ile AYNI teknik (fotoğraf + çift yönlü scrim) —
/// kopya değil, aynı dilin bu ekrana özel bileşimi (burada gerçek asset,
/// `main_theatre.png` — hero'nun Unsplash fotoğrafından bilerek farklı,
/// login/phone-login birbirinden ayırt edilsin diye).
class _StagePanel extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final bool compact;

  const _StagePanel({required this.fade, this.compact = false});

  @override
  Widget build(final BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Image(
          image: AssetImage('assets/images/main_theatre.png'),
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WebColors.veryDarkBlue.withOpacity(0.85),
                WebColors.darkBlueBackground.withOpacity(0.55),
                WebColors.darkBlueBackground.withOpacity(0.30),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                WebColors.veryDarkBlue.withOpacity(0.55),
                Colors.transparent,
                WebColors.veryDarkBlue.withOpacity(0.75),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Tek bir sahne ışığı motifi — hero'daki spotlight dilinin sakin
        // bir yankısı, süs kalabalığı yaratmamak için sadece bir tane.
        Positioned(
          top: -100,
          right: -80,
          child: Opacity(
            opacity: 0.14,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [WebColors.primaryGold, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.section,
            compact ? AppSpacing.xxl : AppSpacing.section,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.end,
            children: [
              if (!compact) ...[
                FadeTransition(
                  opacity: fade(0.0),
                  child: const _BrandMark(),
                ),
                const Spacer(),
              ] else
                const _BrandMark(),
              FadeTransition(
                opacity: fade(0.15),
                child: SlideTransition(
                  position: fade(0.15).drive(
                      Tween(begin: const Offset(0, 0.08), end: Offset.zero)),
                  child: Text(
                    'Perde Açılıyor,\nYerin Sizi Bekliyor.',
                    style: GoogleFonts.playfairDisplay(
                      color: WebColors.whiteText,
                      fontSize: compact ? 30 : 44,
                      fontWeight: FontWeight.w600,
                      height: 1.14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeTransition(
                opacity: fade(0.25),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    'Şehrin en seçkin oyunlarına, konserlerine ve '
                    'sahnelerine anında kapı arala. Sanata ilk adımı at.',
                    style: TextStyle(
                      color: WebColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: WebColors.primaryGold.withOpacity(0.85), width: 1.2),
            ),
            child: const Icon(Icons.theater_comedy_rounded,
                size: 16, color: WebColors.primaryGoldLight),
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
      );
}

/// SAĞ PANEL — form kartı. Sade, gerçek bir web formu gibi: düz kenarlık,
/// asimetrik köşe TEK burada (kartın kendisinde) — ekranın imza vurgusu.
class _FormPanel extends StatelessWidget {
  final Animation<double> Function(double start) fade;
  final bool isLoading;
  final VoidCallback onGoogleTap;
  final VoidCallback onPhoneTap;

  const _FormPanel({
    required this.fade,
    required this.isLoading,
    required this.onGoogleTap,
    required this.onPhoneTap,
  });

  @override
  Widget build(final BuildContext context) {
    return ColoredBox(
      color: WebColors.darkBlueBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
          child: FadeTransition(
            opacity: fade(0.2),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                decoration: BoxDecoration(
                  color: WebColors.darkBlueSurface,
                  borderRadius: AppRadius.asymLg,
                  border: Border.all(color: WebColors.darkBlueAccent),
                  boxShadow: AppShadows.level2(WebColors.veryDarkBlue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GİRİŞ',
                      style: TextStyle(
                        color: WebColors.primaryGoldLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sahneye Hoş Geldiniz',
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: WebColors.whiteText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _WebAuthButton(
                      onTap: isLoading ? null : onGoogleTap,
                      filled: true,
                      icon: const GoogleLogo(size: 20),
                      label: 'Google ile Devam Et',
                      semanticLabel: 'Google ile giriş yap',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: WebColors.darkBlueAccent, height: 1)),
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
                                color: WebColors.darkBlueAccent, height: 1)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _WebAuthButton(
                      onTap: isLoading ? null : onPhoneTap,
                      filled: false,
                      icon: const Icon(Icons.phone_iphone_rounded,
                          size: 18, color: WebColors.primaryGoldLight),
                      label: AppLocalizations.of(context)!.loginPhoneButton,
                      semanticLabel: 'Telefon numarasıyla giriş yap',
                    ),
                    const SizedBox(height: AppSpacing.xxl),
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
        ),
      ),
    );
  }
}

/// Klavye/fare her ikisiyle de tam kullanılabilir buton: `InkWell` (Tab ile
/// odaklanır, Enter/Space ile tetiklenir, `onHover` ile gerçek fare hover
/// durumu) — `home_page_web.dart`'taki `_PillButton`'ın aksine burada
/// bilerek çıplak `GestureDetector` DEĞİL, gerçek `Material`/`InkWell`
/// kullanılıyor (giriş ekranı klavye erişilebilirliğinin en kritik olduğu
/// yer).
class _WebAuthButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool filled;
  final Widget icon;
  final String label;
  final String semanticLabel;

  const _WebAuthButton({
    required this.onTap,
    required this.filled,
    required this.icon,
    required this.label,
    required this.semanticLabel,
  });

  @override
  State<_WebAuthButton> createState() => _WebAuthButtonState();
}

class _WebAuthButtonState extends State<_WebAuthButton> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final bool filled = widget.filled;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: Material(
          color: filled ? WebColors.whiteText : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: widget.onTap,
            onHover: (final v) => setState(() => _hovered = v),
            borderRadius: BorderRadius.circular(AppRadius.md),
            focusColor: WebColors.primaryGold.withOpacity(0.18),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: filled
                    ? null
                    : Border.all(
                        color: WebColors.primaryGold
                            .withOpacity(_hovered ? 0.85 : 0.45),
                        width: 1.4,
                      ),
                boxShadow: filled
                    ? AppShadows.level2(WebColors.veryDarkBlue)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: filled
                          ? const Color(0xFF1F1F1F)
                          : WebColors.whiteText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
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
