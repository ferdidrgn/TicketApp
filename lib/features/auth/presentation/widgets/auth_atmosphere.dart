import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';

/// GİRİŞ EKRANLARININ PAYLAŞILAN "SAHNE ATMOSFERİ" MALZEME KUTUSU — 5. TASARIM
/// (kullanıcının paylaştığı somut görsel referans — tek büyük yuvarlak köşeli
/// afiş kartı: üstte dev başlık, ortada/altta tam-kanama bir editoryal
/// fotoğraf, fotoğrafın alt kenarını bindiren tek bir yüzen pill CTA).
///
/// 3. tasarımın "fotoğrafsız editoryal tipografi + kadro listesi" dili
/// KÖKTEN terk edildi (kullanıcı "berbat" dedi) — bu sürüm fotoğrafı
/// yeniden ana anlatıcı yapıyor, AMA kullanıcının BEĞENDİĞİ tek şeyi
/// (`AuthWipeReveal` — perde açılışıyla AYNI teknik: `ClipRect` +
/// `Align(widthFactor: ...)`) aynen koruyor.
///
/// Referansın açık pastel paleti KOPYALANMADI — uygulamanın kendi koyu
/// (near-black) + kırmızı/altın mücevher tonu kimliği (`WebColors`)
/// korunuyor; sadece KOMPOZİSYON (tek afiş kartı → dev başlık → tam-kanama
/// fotoğraf → yüzen pill CTA) referanstan alındı.
///
/// Buradaki parçalar platforma özgü DEĞİL — her sayfanın gerçek İSKELETİ
/// (`login_screen_web.dart` vs `login_screen_mobile.dart`,
/// `phone_login_page_web.dart` vs `phone_login_page_mobile.dart`) tamamen
/// ayrı kalıyor, bu sadece ortak bir görsel malzeme kutusu.

/// Paylaşılan zemin: uygulamanın kendi çok-durak koyu gradyanı
/// (`WebColors.backgroundGradient` — YENİ bir hex icat edilmedi, zaten var
/// olan sabit gradyan token'ı kullanılıyor) + çağıranın konumlandırdığı
/// (0-2 adet) `AuthAmbientGlow` ışığı. 4 sayfanın da az önce elle tekrar
/// tekrar yazdığı neredeyse birebir aynı 3 renkli gradyanın yerini alıyor.
class AuthStageBackdrop extends StatelessWidget {
  final List<Widget> glows;

  const AuthStageBackdrop({super.key, this.glows = const []});

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: WebColors.backgroundGradient),
          ),
          ...glows,
        ],
      );
}

/// Tek, sakin "nefes alan" spot ışığı — sayfa başına TEK bir tane (kural:
/// "süs kalabalığı yaratma"). Azaltılmış hareket (`disableAnimations`)
/// tercih edilmişse döngüsel animasyon hiç başlamaz, sabit bir orta
/// değerde durur.
class AuthAmbientGlow extends StatefulWidget {
  final double size;
  final Color tint;

  const AuthAmbientGlow({super.key, required this.size, required this.tint});

  @override
  State<AuthAmbientGlow> createState() => _AuthAmbientGlowState();
}

class _AuthAmbientGlowState extends State<AuthAmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _opacity = Tween<double>(begin: 0.10, end: 0.20)
      .animate(CurvedAnimation(parent: _controller, curve: AppMotion.symmetric));

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [widget.tint, widget.tint.withOpacity(0)],
              ),
            ),
          ),
        ),
      );
}

/// Sahne perdesi açılışıyla AYNI teknik (`page_transitions.dart`
/// `curtainTransition`, `theatre_show_card.dart`'ın hover reveal'i —
/// `ClipRect` + ortadan/kenardan büyüyen `Align(widthFactor: ...)`).
/// Burada bir görsel değil, bir metin bloğu bu şekilde "açılıyor" —
/// kullanıcının 3. denemeden AÇIKÇA BEĞENDİĞİ tek teknik, aynen korunuyor.
class AuthWipeReveal extends StatelessWidget {
  final Animation<double> reveal;
  final Alignment alignment;
  final Widget child;

  const AuthWipeReveal({
    super.key,
    required this.reveal,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: reveal,
        builder: (final context, final child) => ClipRect(
          child: Align(
            alignment: alignment,
            widthFactor: reveal.value.clamp(0.0001, 1.0),
            child: child,
          ),
        ),
        child: child,
      );
}

/// Küçük "adım/durum" rozeti — telefon/OTP ekranının hangi anında
/// olduğumuzu (iletişim vs. doğrulama) tek bakışta gösterir.
class AuthStepChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const AuthStepChip({super.key, required this.icon, required this.label});

  @override
  Widget build(final BuildContext context) => Semantics(
        label: label,
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
              Icon(icon, color: WebColors.primaryGoldLight, size: 15),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: WebColors.whiteText.withOpacity(0.9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
}

/// "Afiş kartı"nın fotoğraf bandı — referans görseldeki tam-kanama editoryal
/// fotoğrafın karşılığı. `home_page_web.dart`'taki `_HeroBackdropPhoto` ile
/// AYNI teknik: gerçek bir fotoğraf + okunabilirliği garanti eden çift
/// yönlü koyu "scrim" gradyanı (üstte kart dikişiyle kaynaşması için hafif,
/// altta üzerine bindirilecek pill CTA'nın her zaman net okunması için
/// güçlü). `OptimizedCachedImage` üzerinden — gerçek önbellekleme + shimmer
/// yükleme durumu var, kırık görsel asla çıplak gösterilmiyor.
class AuthHeroPoster extends StatelessWidget {
  final String imageUrl;

  /// Fotoğrafın üzerine bindirilen, isteğe bağlı küçük bir rozet (ör.
  /// `AuthStepChip`) — afişin köşesindeki bir "tür etiketi" gibi.
  final Widget? topOverlay;
  final Alignment topOverlayAlignment;

  const AuthHeroPoster({
    super.key,
    required this.imageUrl,
    this.topOverlay,
    this.topOverlayAlignment = Alignment.topLeft,
  });

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          OptimizedCachedImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            borderRadius: 0,
          ),
          // Üst scrim: başlık bandından fotoğrafa geçen dikişi yumuşatır.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WebColors.veryDarkBlue.withOpacity(0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.32],
              ),
            ),
          ),
          // Alt scrim: yüzen pill CTA'nın hangi fotoğrafın üzerine
          // bindirilirse bindirilsin her zaman net okunması için.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  WebColors.veryDarkBlue.withOpacity(0.88),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          if (topOverlay != null)
            Positioned(
              top: AppSpacing.md,
              left: topOverlayAlignment == Alignment.topLeft
                  ? AppSpacing.md
                  : null,
              right: topOverlayAlignment == Alignment.topRight
                  ? AppSpacing.md
                  : null,
              child: topOverlay!,
            ),
        ],
      );
}

/// Referans afişteki TEK, yüzen, tam-yuvarlak (pill) birincil aksiyon
/// butonu — ekranın her zaman TEK net birincil aksiyonu. `AppRadius.pill`
/// (kural 7'nin açıkça izin verdiği "pill okunaklıysa kullan" seçeneği) +
/// uygulamanın kendi altın gradyanı (`WebColors.goldButtonGradient`) ile
/// dolduruluyor — near-black fotoğrafın üzerinde yüksek kontrast, "mücevher
/// tonu" kimliğiyle uyumlu. `height` sabiti (54) hem gerçek dokunma hedefi
/// (>=48px) hem de kartların üzerine bindiği "yarım pill" taşma hesabı
/// (`height / 2`) için tek doğruluk kaynağı.
class AuthFloatingPillCTA extends StatefulWidget {
  static const double height = 54;

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const AuthFloatingPillCTA({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  State<AuthFloatingPillCTA> createState() => _AuthFloatingPillCTAState();
}

class _AuthFloatingPillCTAState extends State<AuthFloatingPillCTA> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final bool enabled = widget.onTap != null;

    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            focusColor: WebColors.whiteText.withOpacity(0.18),
            splashColor: WebColors.veryDarkBlue.withOpacity(0.12),
            highlightColor: WebColors.veryDarkBlue.withOpacity(0.06),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: AuthFloatingPillCTA.height,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              decoration: BoxDecoration(
                gradient: enabled ? WebColors.goldButtonGradient : null,
                color: enabled ? null : WebColors.darkBlueAccent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: enabled
                    ? (_hovered ? AppShadows.level5 : AppShadows.level4)(
                        WebColors.primaryGold)
                    : AppShadows.level0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon,
                        size: 19,
                        color: enabled
                            ? WebColors.veryDarkBlue
                            : WebColors.textTertiary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? WebColors.veryDarkBlue
                            : WebColors.textTertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.6,
                      ),
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

/// İkincil, "sessiz" aksiyon — ekranın TEK yüzen pill'ini
/// (`AuthFloatingPillCTA`) hiçbir zaman gölgede bırakmayan, dolgusuz/
/// gölgesiz bir çerçeve-pill. 3. denemenin numaralı "marquee" satır
/// listesinin YERİNE geçmiyor (o dil tamamen kaldırıldı) — tek ikincil yol
/// için tek, sakin bir kontrol.
class AuthGhostPillButton extends StatefulWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  const AuthGhostPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  State<AuthGhostPillButton> createState() => _AuthGhostPillButtonState();
}

class _AuthGhostPillButtonState extends State<AuthGhostPillButton> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final bool enabled = widget.onTap != null;
    final Color borderColor = _hovered
        ? WebColors.primaryGoldLight.withOpacity(0.6)
        : WebColors.primaryGold.withOpacity(0.3);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            splashColor: WebColors.primaryGold.withOpacity(0.08),
            highlightColor: WebColors.primaryGold.withOpacity(0.05),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.icon,
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            WebColors.whiteText.withOpacity(enabled ? 0.92 : 0.4),
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        letterSpacing: 0.3,
                      ),
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
