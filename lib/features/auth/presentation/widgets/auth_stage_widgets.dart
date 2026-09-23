import 'package:flutter/material.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';

/// "SAHNE KAPISI" (Stage Door) — giriş akışının (login_screen +
/// phone_login_page) paylaştığı görsel dil.
///
/// Eskiden ikisi de "tam ekran fotoğraf + karartma gradyanı + üzerinde
/// bulanık cam kart" formülünü tekrarlıyordu. Burada onun yerine geçen
/// PARÇALAR: `AuthCurtainStage` (mount'ta bir kez açılan, `page_transitions
/// .dart`'taki `curtainTransition` ve `theatre_show_card.dart`'ın hover
/// reveal'ıyla AYNI `ClipRect`+`Align(widthFactor)` tekniğini kullanan
/// küçük/sahne paneli), `AuthHeadlineBlock` (kicker/başlık/alt başlık),
/// `AuthActionButton` (gradyan CTA) ve `AuthStageScaffold` (mobilde tek
/// sütun, masaüstünde/webde GERÇEK split-screen — `home_page_web.dart` /
/// `home_page_mobile.dart` ikilisindeki "platforma özel gerçek kompozisyon"
/// prensibiyle aynı). İki sayfa da bu dosyayı kullandığı için görsel dilleri
/// otomatik olarak tutarlı kalır.

/// Sayfa açıldığında BİR KEZ, gerçek bir tiyatro perdesi gibi ortadan
/// açılarak arkasındaki görseli ortaya çıkaran sahne paneli.
///
/// Taban katman "kapalı perde" rengidir (her zaman görünür); üzerine
/// `curtainTransition`/`theatre_show_card` ile birebir aynı `ClipRect(
/// Align(widthFactor: t))` tekniğiyle görsel açılır. `t` burada hover değil,
/// `initState` sonrası bir kerelik `AnimationController.forward()` ile
/// sürülüyor — widget kendi animasyonunu yönetir, çağıran taraf sadece
/// boyut/renk/overlay verir.
class AuthCurtainStage extends StatefulWidget {
  final String imagePath;
  final BorderRadius borderRadius;
  final Color curtainColor;

  /// Panelin alt kenarına oturan, isteğe bağlı dekoratif katman (rozet ya
  /// da büyük editoryal başlık bloğu) — konumlandırmayı panel kendi yapar.
  final Widget? overlay;

  const AuthCurtainStage({
    super.key,
    required this.imagePath,
    required this.borderRadius,
    required this.curtainColor,
    this.overlay,
  });

  @override
  State<AuthCurtainStage> createState() => _AuthCurtainStageState();
}

class _AuthCurtainStageState extends State<AuthCurtainStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curtain;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _curtain =
        CurvedAnimation(parent: _controller, curve: AppMotion.dramatic);
    // Sahneye girer girmez perde bir kez açılsın — build sırasında değil,
    // ilk frame çizildikten hemen sonra (aksi halde setState-during-build
    // uyarısı riski var).
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: AppShadows.level4(widget.curtainColor),
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. "Kapalı perde" — taban katman, her zaman görünür.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.curtainColor,
                      widget.curtainColor.withOpacity(0.72),
                    ],
                  ),
                ),
              ),

              // 2. Perde açılışıyla ortaya çıkan görsel — teknik
              // `theatre_show_card.dart`'ın hover reveal'ıyla birebir aynı.
              AnimatedBuilder(
                animation: _curtain,
                builder: (final context, final child) {
                  if (_curtain.value <= 0) return const SizedBox.shrink();
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.center,
                      widthFactor: _curtain.value,
                      child: child,
                    ),
                  );
                },
                child: SizedBox.expand(
                  child: Image.asset(widget.imagePath, fit: BoxFit.cover),
                ),
              ),

              // 3. Okunabilirlik için alttan karartma — overlay içeriği
              // (rozet/başlık) hep alt kenarda oturduğundan sadece orası
              // karartılıyor, görsel bütün olarak karartılmıyor.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              if (widget.overlay != null)
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: widget.overlay!,
                ),
            ],
          ),
        ),
      );
}

/// Kicker + büyük başlık + alt başlık + vurgu çizgisi. Normal sayfa
/// zemininin (fotoğraf değil) ÜZERİNDE olduğu için renkler tema-uyumlu
/// (`context.colors`) — light/dark ikisinde de okunur kalır.
class AuthHeadlineBlock extends StatelessWidget {
  final String kicker;
  final String title;
  final String subtitle;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  const AuthHeadlineBlock({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          kicker.toUpperCase(),
          textAlign: textAlign,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 36,
            height: 0.98,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 56,
          height: 5,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          subtitle,
          textAlign: textAlign,
          style: TextStyle(
            color: colors.onSurface.withOpacity(0.64),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Tam genişlikte, gradyanlı çağrı-eylem (CTA) butonu. `useAsymCorner`
/// true ise uygulamanın imza asimetrik köşesi (`AppRadius.asymSm`)
/// kullanılır — bu akışın "bir-iki vurgu noktası"ndan biri budur.
class AuthActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool useAsymCorner;
  final bool isBusy;

  const AuthActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.useAsymCorner = false,
    this.isBusy = false,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final BorderRadius radius =
        useAsymCorner ? AppRadius.asymSm : BorderRadius.circular(AppRadius.lg);

    return Semantics(
      button: true,
      enabled: !isBusy,
      label: semanticLabel,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: radius,
        child: Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
            borderRadius: radius,
            boxShadow: AppShadows.level3(colors.primary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Giriş akışının paylaşılan iskeleti: mobilde tek sütun (sahne paneli ->
/// başlık -> form kartı), masaüstünde/webde GERÇEK split-screen (solda
/// büyük/uzun sahne paneli, sağda dar ve ortalanmış form sütunu). İki
/// giriş sayfası da (Google/telefon seçimi ve telefon+OTP akışı) bunu
/// kullandığı için kompozisyon otomatik olarak birebir tutarlı kalır.
class AuthStageScaffold extends StatelessWidget {
  /// `isLargeScreen` sahne panelinin mobil (kompakt rozet) mi yoksa
  /// masaüstü (büyük editoryal başlık) overlay'i mi alacağını seçebilsin
  /// diye builder olarak veriliyor.
  final Widget Function(BuildContext context, bool isLargeScreen)
      stagePanelBuilder;
  final Widget headline;
  final Widget formCard;
  final Widget? finePrint;

  const AuthStageScaffold({
    super.key,
    required this.stagePanelBuilder,
    required this.headline,
    required this.formCard,
    this.finePrint,
  });

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    return isLargeScreen ? _buildDesktop(context) : _buildMobile(context);
  }

  Widget _buildMobile(final BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 280, child: stagePanelBuilder(context, false)),
            const SizedBox(height: AppSpacing.xxxl),
            headline,
            const SizedBox(height: AppSpacing.section),
            formCard,
            if (finePrint != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              finePrint!,
            ],
          ],
        ),
      );

  Widget _buildDesktop(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: stagePanelBuilder(context, true),
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.section,
                      horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      headline,
                      const SizedBox(height: AppSpacing.section),
                      formCard,
                      if (finePrint != null) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        finePrint!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

/// Sahne panelinin altına oturan kompakt marka rozeti (mobil + masaüstü
/// küçük varyant). Görsel her zaman gerçek bir fotoğraf olduğu için metin
/// rengi kasıtlı olarak beyaz/siyah sabit — tema bağımsız kontrast.
class StageBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const StageBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
}

/// Masaüstü/web split-screen'in sol panelindeki büyük editoryal başlık —
/// sahne görselinin üzerine oturan marka hikayesi bloğu. Görsel her zaman
/// fotoğraf olduğu için (tema bağımsız kontrast) beyaz metin kasıtlı.
class StageEditorialCaption extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const StageEditorialCaption({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              height: 0.98,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      );
}

/// İki-kollu "veya" ayracı — Google ve telefon seçeneklerini birbirinden
/// ayırmak için.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final line = Divider(color: colors.onSurface.withOpacity(0.14), height: 1);
    return Row(
      children: [
        Expanded(child: line),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'VEYA',
            style: TextStyle(
              color: colors.onSurface.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(child: line),
      ],
    );
  }
}
