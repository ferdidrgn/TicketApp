import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../optimized_cached_image.dart';

/// "SAHNE" tasarım kiti — ana sayfa, arama, oyun ve oyuncu sayfalarının
/// ortak parçaları. Renkler daima temadan (`ColorScheme`): 5 tema bozulmaz.
/// Görsel her zaman gerçek afiş/fotoğraf; hareket sadece anlamlı yerde
/// (ilk belirme, dokunuşa cevap, vitrin kayması) ve `disableAnimations`
/// açıkken kapanır.
class Sk {
  const Sk._();

  /// Başlık / afiş adı — Playfair Display.
  static TextStyle display(
    final BuildContext context, {
    final double size = 32,
    final Color? color,
    final double height = 1.08,
    final FontWeight weight = FontWeight.w800,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: -0.3,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  /// Arayüz metni — Manrope.
  static TextStyle ui(
    final BuildContext context, {
    final double size = 14,
    final Color? color,
    final FontWeight weight = FontWeight.w600,
    final double height = 1.3,
    final double letterSpacing = 0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );

  static bool reduceMotion(final BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Sayfa kenar boşluğu — genişliğe göre.
  static double gutter(final double width) =>
      width >= 1100 ? 56 : (width >= 700 ? 32 : 20);

  static const double maxWidth = 1240;
}

// ─── Tarih yardımcıları (Türkçe) ────────────────────────────────────────────

const List<String> kMonthsTr = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];
const List<String> kMonthsShortTr = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', //
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];
const List<String> kDaysTr = [
  'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
];
const List<String> kDaysShortTr = [
  'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz',
];

DateTime skDay(final DateTime d) => DateTime(d.year, d.month, d.day);

String skClock(final DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "Bugün", "Yarın", "Cumartesi" (7 gün içinde) ya da "12 Ekim".
String skDayPhrase(final DateTime date) {
  final DateTime today = skDay(DateTime.now());
  final int diff = skDay(date).difference(today).inDays;
  if (diff == 0) return 'Bugün';
  if (diff == 1) return 'Yarın';
  if (diff > 1 && diff < 7) return kDaysTr[date.weekday - 1];
  return '${date.day} ${kMonthsTr[date.month - 1]}';
}

/// "15 Ekim · 22:00".
String skDateTime(final DateTime d) =>
    '${d.day} ${kMonthsTr[d.month - 1]} · ${skClock(d)}';

/// Sayı + birim için ₺ biçimi.
String skPrice(final double price) => price == price.roundToDouble()
    ? '${price.toInt()} ₺'
    : '${price.toStringAsFixed(2)} ₺';

// ─── Dokunuş: ölçek + haptic ────────────────────────────────────────────────

/// Basılınca hafifçe küçülen, `Semantics(button)` ve InkWell'siz tutarlı
/// dokunuş yüzeyi. 48dp altı hedefler çağıran tarafta doldurulmalı.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final double scale;
  final bool haptic;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.scale = 0.97,
    this.haptic = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(final bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(final BuildContext context) {
    final bool reduce = Sk.reduceMotion(context);
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapCancel: () => _set(false),
          onTapUp: (_) => _set(false),
          onTap: widget.onTap == null
              ? null
              : () {
                  if (widget.haptic) HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: _down && !reduce ? widget.scale : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ─── Belirme (reveal) ───────────────────────────────────────────────────────

/// İlk çizimde aşağıdan yumuşakça beliren sarmalayıcı. Listede `index`
/// ile sıralı gecikme verilir (en çok 8 öğe: sonrası gecikmesiz).
class Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final double dy;

  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 55),
    this.dy = 18,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Sk.reduceMotion(context)) {
      _c.value = 1;
      return;
    }
    final int step = widget.index.clamp(0, 8);
    Future<void>.delayed(widget.baseDelay * step, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (final context, final child) => Opacity(
          opacity: _t.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _t.value) * widget.dy),
            child: child,
          ),
        ),
      );
}

// ─── Görsel ─────────────────────────────────────────────────────────────────

/// Afiş / fotoğraf — yüklenemezse temadan türeyen sade yedek yüzey.
class SkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final IconData fallbackIcon;

  const SkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 0,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.theater_comedy_rounded,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surfaceContainerHigh, cs.surfaceContainerHighest],
        ),
      ),
      child: Icon(fallbackIcon,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 32),
    );
    if (!url.trim().startsWith('http')) return fallback;
    return OptimizedCachedImage(
      imageUrl: url.trim(),
      width: width,
      height: height,
      fit: fit,
      borderRadius: radius,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// Afişten türeyen bulanık "ortam" zemini — sayfanın üstünde yumuşak renk
/// verir, altta zemine karışır. URL değişince çapraz geçişle değişir.
class AmbientBackdrop extends StatelessWidget {
  final String url;
  final double height;
  final double blur;
  final double opacity;

  const AmbientBackdrop({
    super.key,
    required this.url,
    this.height = 520,
    this.blur = 36,
    this.opacity = 0.55,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: url.trim().startsWith('http')
                  ? KeyedSubtree(
                      key: ValueKey<String>(url),
                      child: ClipRect(
                        child: ImageFiltered(
                          imageFilter:
                              ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                          child: Opacity(
                            opacity: opacity,
                            child: SkImage(url: url),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.expand(key: ValueKey<String>('none')),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.surface.withValues(alpha: 0.0),
                    cs.surface.withValues(alpha: 0.55),
                    cs.surface,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Başlık, çip, rozet ─────────────────────────────────────────────────────

class SkSectionHead extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SkSectionHead({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (icon != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: cs.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 21, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title,
                    style: Sk.display(context, size: 24, height: 1.1)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: Sk.ui(context,
                        size: 13,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w500)),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          PressScale(
            onTap: onAction,
            semanticLabel: actionLabel,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(actionLabel!,
                  style: Sk.ui(context,
                      size: 13, color: cs.primary, weight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class SkChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  const SkChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = selected ? cs.onPrimary : cs.onSurface;
    return PressScale(
      onTap: onTap,
      semanticLabel: label,
      scale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : cs.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: Sk.ui(context,
                    size: 13.5, color: fg, weight: FontWeight.w700)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text('$count',
                  style: Sk.ui(context,
                      size: 12,
                      color: fg.withValues(alpha: 0.7),
                      weight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Küçük bilgi rozeti (afiş üstü ya da düz zemin).
class SkBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool onImage;
  final bool accent;

  const SkBadge({
    super.key,
    required this.label,
    this.icon,
    this.onImage = false,
    this.accent = false,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = accent
        ? cs.primary
        : (onImage
            ? Colors.black.withValues(alpha: 0.55)
            : cs.surfaceContainerHigh);
    final Color fg = accent
        ? cs.onPrimary
        : (onImage ? Colors.white : cs.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Sk.ui(context,
                  size: 11.5, color: fg, weight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

/// Yükleniyor iskeleti — spinner yerine nabız atan kutu.
class SkBone extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkBone({super.key, this.width, required this.height, this.radius = 16});

  @override
  State<SkBone> createState() => _SkBoneState();
}

class _SkBoneState extends State<SkBone> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool reduce = Sk.reduceMotion(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (final context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(cs.surfaceContainerHigh, cs.surfaceContainerHighest,
              reduce ? 0 : _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Boş / hata durumu — davet + tek aksiyon.
class SkEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SkEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: cs.primary, size: 32),
              ),
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Sk.display(context, size: 22)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Sk.ui(context,
                      size: 14,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w500,
                      height: 1.5)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Yatay şeritte fare sürüklemesini de açan kaydırma davranışı (web).
class SkScrollBehavior extends MaterialScrollBehavior {
  const SkScrollBehavior();
  @override
  Set<ui.PointerDeviceKind> get dragDevices => {
        ui.PointerDeviceKind.touch,
        ui.PointerDeviceKind.mouse,
        ui.PointerDeviceKind.trackpad,
        ui.PointerDeviceKind.stylus,
      };
}

/// Cam yüzey — fotoğrafın üstündeki rozet/ikon/buton zemini (hafif bulanık,
/// yarı saydam beyaz). Sadece görselin ÜSTÜNDE kullanılır; metin her zaman
/// beyazdır.
class SkGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;

  const SkGlass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.opacity = 0.16,
  });

  @override
  Widget build(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: child,
          ),
        ),
      );
}

/// Yumuşak, tonlu kart gölgesi (Material soft).
List<BoxShadow> skSoftShadow(final BuildContext context,
    {final double strength = 1}) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: (dark ? 0.32 : 0.10) * strength),
      blurRadius: 26,
      offset: const Offset(0, 12),
    ),
  ];
}


// ─── Şerit + aşağı açılan ızgara ────────────────────────────────────────────

/// En fazla [max] öğelik YATAY şerit. Başlığın yanındaki "Tümü" bu kategoriyi
/// yerinde AŞAĞI DOĞRU ızgaraya açar; "Daralt" geri toplar. Sahibinin kararı:
/// arama ve ana sayfadaki her kategori bu bileşenle çizilir.
class SkRail<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<T> items;
  final double gutter;
  final double railW;
  final double railH;
  final double gap;
  final int max;

  /// Izgarada bir hücrenin en az genişliği (sütun sayısı buradan çıkar).
  final double minCell;
  final Widget Function(T item, double width) builder;

  /// Başlıkla şerit arasına girecek ek yüzey (ör. gün şeridi).
  final Widget? belowHeader;

  const SkRail({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.items,
    required this.gutter,
    required this.railW,
    required this.railH,
    required this.minCell,
    required this.builder,
    this.gap = 14,
    this.max = 10,
    this.belowHeader,
  });

  @override
  State<SkRail<T>> createState() => _SkRailState<T>();
}

class _SkRailState<T> extends State<SkRail<T>> {
  bool _open = false;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _open = !_open);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool more = widget.items.length > widget.max;
    final List<T> railItems = widget.items.take(widget.max).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
        child: LayoutBuilder(builder: (final context, final box) {
          final double inner = box.maxWidth - 2 * widget.gutter;

          final Widget content;
          if (_open) {
            final int cols =
                ((inner + widget.gap) / (widget.minCell + widget.gap))
                    .floor()
                    .clamp(1, 12)
                    .toInt();
            final double cell = (inner - widget.gap * (cols - 1)) / cols;
            content = Padding(
              key: const ValueKey<String>('grid'),
              padding: EdgeInsets.symmetric(horizontal: widget.gutter),
              child: Wrap(
                spacing: widget.gap,
                runSpacing: 18,
                children: [
                  for (int i = 0; i < widget.items.length; i++)
                    SizedBox(
                      width: cell,
                      child: Reveal(
                        index: i % cols,
                        dy: 10,
                        child: widget.builder(widget.items[i], cell),
                      ),
                    ),
                ],
              ),
            );
          } else {
            content = SizedBox(
              key: const ValueKey<String>('rail'),
              height: widget.railH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: widget.gutter),
                itemCount: railItems.length + (more ? 1 : 0),
                separatorBuilder: (_, __) => SizedBox(width: widget.gap),
                itemBuilder: (final context, final i) {
                  if (i == railItems.length) {
                    return PressScale(
                      onTap: _toggle,
                      semanticLabel: '${widget.title} tümünü göster',
                      child: Container(
                        width: 116,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: cs.primary, shape: BoxShape.circle),
                              child: Icon(Icons.arrow_downward_rounded,
                                  color: cs.onPrimary),
                            ),
                            const SizedBox(height: 10),
                            Text('+${widget.items.length - widget.max}',
                                style: Sk.display(context,
                                    size: 22, height: 1.0)),
                            Text('daha',
                                style: Sk.ui(context,
                                    size: 12,
                                    color: cs.onSurfaceVariant,
                                    weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    );
                  }
                  return widget.builder(railItems[i], widget.railW);
                },
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.gutter),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle),
                        child: Icon(widget.icon,
                            size: 21, color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(widget.title,
                                style:
                                    Sk.display(context, size: 24, height: 1.1)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle ?? '${widget.items.length} sonuç',
                            style: Sk.ui(context,
                                size: 12.5,
                                color: cs.onSurfaceVariant,
                                weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (more || _open)
                      PressScale(
                        onTap: _toggle,
                        semanticLabel: _open ? 'Daralt' : 'Tümünü göster',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_open ? 'Daralt' : 'Tümü',
                                  style: Sk.ui(context,
                                      size: 13,
                                      color: cs.onSecondaryContainer,
                                      weight: FontWeight.w800)),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _open ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 18, color: cs.onSecondaryContainer),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (widget.belowHeader != null) widget.belowHeader!,
              AnimatedSize(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  layoutBuilder: (final current, final previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: content,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
