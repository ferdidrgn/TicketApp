import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';

/// GİRİŞ EKRANLARININ PAYLAŞILAN "SAHNE ATMOSFERİ" MALZEME KUTUSU.
///
/// Kullanıcının açık talebi üzerine (`login_screen_*`/`phone_login_page_*`
/// — 3. deneme) ikisi de daha önce "fotoğraf paneli + form" iskeletini
/// tekrarlıyordu. Bu üçüncü tasarım kökten farklı bir yapı kullanıyor:
/// fotoğraf yerine EDİTORYAL TİPOGRAFİ + tek bir "nefes alan" spot ışığı +
/// bir tiyatro programı gibi numaralanmış "marquee" satırları (bkz.
/// araştırma: 2025/2026 login/OTP trendleri minimalizm, pasif ışık/derinlik,
/// sadece geri bildirime hizmet eden mikro-etkileşimleri işaret ediyor —
/// Dribbble/Mobbin'deki "kart üstüne kart" login şablonlarının TERSİ).
///
/// Buradaki parçalar platforma özgü DEĞİL — `GlassmorphismBackButton`/
/// `GoogleLogo`/`TheatreShowCard`'ın zaten web+mobil arasında paylaşıldığı
/// gibi, bu da sadece ortak bir görsel malzeme kutusu. Her sayfanın
/// gerçek İSKELETİ (`login_screen_web.dart` vs `login_screen_mobile.dart`,
/// `phone_login_page_web.dart` vs `phone_login_page_mobile.dart`) tamamen
/// ayrı kalıyor — CLAUDE.md'nin "mobile'ı büyütüp web diye sunma" kuralı bu
/// dosyanın kapsamı DIŞINDA, sayfa dosyalarının kendisinde korunuyor.

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
/// Burada bir görsel değil, bir metin bloğu bu şekilde "açılıyor" — aynı
/// dilin yeni bir uygulaması, kopyala-yapıştır değil.
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

/// "Sahne kapısındaki gözetleme deliği" — telefon/OTP ekranının imza
/// görseli. Büyük bir fotoğraf PANELİ değil, tek bir dairesel "porthole" +
/// çevresindeki `AuthAmbientGlow` halkası. Fotoğraf `OptimizedCachedImage`
/// (`isCircular: true`) üzerinden — çıplak `Image(NetworkImage(...))`
/// yerine artık gerçek önbellekleme + shimmer yükleme durumu var.
class AuthPortholePhoto extends StatelessWidget {
  final String imageUrl;
  final double size;

  const AuthPortholePhoto({
    super.key,
    required this.imageUrl,
    this.size = 132,
  });

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: size + 40,
          height: size + 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AuthAmbientGlow(size: size + 40, tint: WebColors.primaryGold),
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WebColors.primaryGold.withOpacity(0.55),
                    width: 1.6,
                  ),
                  boxShadow: AppShadows.level3(WebColors.veryDarkBlue),
                ),
                child: OptimizedCachedImage(
                  imageUrl: imageUrl,
                  width: size - 8,
                  height: size - 8,
                  isCircular: true,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      );
}

/// "Marquee" (program) satırı — pill/kart buton yerine, bir tiyatro
/// programındaki kadro listesi gibi numaralı, alt çizgili bir satır. Kart
/// çerçevesi/gölgesi/arka planı yok — hiyerarşi tamamen tipografi + tek
/// çizgi kalınlığı ile kuruluyor (kural: "her elemanda shadow/border
/// olmasın"). `InkWell` kullanıldığı için hem web'de Tab/Enter ile hem
/// mobilde dokunuşla tam çalışır.
class AuthMarqueeRow extends StatefulWidget {
  final String index;
  final Widget icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool emphasize;

  const AuthMarqueeRow({
    super.key,
    required this.index,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.emphasize = false,
  });

  @override
  State<AuthMarqueeRow> createState() => _AuthMarqueeRowState();
}

class _AuthMarqueeRowState extends State<AuthMarqueeRow> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final bool enabled = widget.onTap != null;
    final Color lineColor =
        _hovered ? WebColors.primaryGoldLight : WebColors.darkBlueAccent;

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
          child: InkWell(
            onTap: widget.onTap,
            focusColor: WebColors.primaryGold.withOpacity(0.08),
            splashColor: WebColors.primaryGold.withOpacity(0.08),
            highlightColor: WebColors.primaryGold.withOpacity(0.05),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
                horizontal: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      BorderSide(color: lineColor, width: _hovered ? 1.6 : 1),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      widget.index,
                      style: TextStyle(
                        color: WebColors.primaryGoldLight
                            .withOpacity(enabled ? 0.9 : 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  widget.icon,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color:
                            WebColors.whiteText.withOpacity(enabled ? 1 : 0.4),
                        fontWeight: widget.emphasize
                            ? FontWeight.w800
                            : FontWeight.w700,
                        fontSize: 15.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  AnimatedSlide(
                    duration: AppMotion.fast,
                    curve: AppMotion.standard,
                    offset:
                        _hovered ? const Offset(0.06, -0.06) : Offset.zero,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: WebColors.textTertiary
                          .withOpacity(enabled ? 1 : 0.4),
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

/// Büyük birincil CTA butonu — telefon/OTP ekranının aksiyon anı için.
/// Ekranın TEK imza asimetrik köşe (`AppRadius.asymLg`) vurgu noktası
/// burada (kural: "bir-iki vurgu noktasında kullan, her yerde değil").
class AuthPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
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
          color: WebColors.whiteText,
          borderRadius: AppRadius.asymLg,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.asymLg,
            focusColor: WebColors.primaryGold.withOpacity(0.18),
            splashColor: Colors.black.withOpacity(0.08),
            highlightColor: Colors.black.withOpacity(0.04),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: 54,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.asymLg,
                boxShadow: (_hovered ? AppShadows.level3 : AppShadows.level2)(
                    WebColors.veryDarkBlue),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: WebColors.veryDarkBlue),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: WebColors.veryDarkBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      letterSpacing: 0.6,
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
