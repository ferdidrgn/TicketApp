import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/craft.dart';
import '../../../../shared/widgets/listing.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart' show Reveal;
import '../../../../shared/widgets/ticket/ticket_kit.dart' show AuthWipeReveal;
import '../../../shows/domain/entities/show.dart';

/// Keşfet / Yakınımdakiler / Arama ekranlarının ortak, temaya bağlı tarama
/// kontrolleri. Bunlar "araç" parçalarıdır (filtre, başlık, liste satırı) —
/// bilet dili sadece gerçekten bilet olan nesnelerde (oyun, seans) kullanılır,
/// burada değil. Bütün renkler `ColorScheme`'dan gelir: 5 tema korunur.

/// CSS `clamp()` karşılığı: ekran genişliğine göre [min]–[max] arası değer.
double browseFluid(final BuildContext context, final double min,
    final double max,
    {final double minW = 375, final double maxW = 1440}) {
  final double w = MediaQuery.sizeOf(context).width;
  final double t = ((w - minW) / (maxW - minW)).clamp(0.0, 1.0);
  return min + (max - min) * t;
}

/// Yatay listelerin web'de fareyle de sürüklenebilmesi için kaydırma
/// davranışı (Flutter web'de fare sürüklemesi varsayılan olarak kapalı).
class BrowseDragScrollBehavior extends MaterialScrollBehavior {
  const BrowseDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// ─────────────────────────────────────────────────────────────────────────
// Sayfa başlığı
// ─────────────────────────────────────────────────────────────────────────

/// Sayfa başlığı — Playfair + soldan sağa perde açılışı (onaylı wipe).
class BrowseHeading extends StatefulWidget {
  final String title;
  final String? lede;

  const BrowseHeading({super.key, required this.title, this.lede});

  @override
  State<BrowseHeading> createState() => _BrowseHeadingState();
}

class _BrowseHeadingState extends State<BrowseHeading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _reveal =
      CurvedAnimation(parent: _controller, curve: AppMotion.dramatic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: AuthWipeReveal(
            reveal: _reveal,
            child: Text(
              widget.title,
              style: GoogleFonts.playfairDisplay(
                color: cs.onSurface,
                fontSize: browseFluid(context, 32, 48),
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        if (widget.lede != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Text(
                widget.lede!,
                key: ValueKey(widget.lede),
                style: listingUi(
                  color: cs.onSurfaceVariant,
                  size: 15,
                  weight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bölüm başlığı: sade Playfair başlık + (varsa) gerçek sayı + opsiyonel
/// "Tümünü gör". Üstünde etiket (eyebrow) yok.
class BrowseSectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BrowseSectionTitle({
    super.key,
    required this.title,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  color: cs.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$count',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                minimumSize: const Size(48, 44),
              ),
              child: Text(
                actionLabel ?? 'Tümünü gör',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Filtreler
// ─────────────────────────────────────────────────────────────────────────

/// Seçenek: görünen ad + (varsa) gerçek öğe sayısı.
class BrowseOption {
  final String label;
  final int? count;
  final IconData? icon;
  const BrowseOption(this.label, {this.count, this.icon});
}

/// "Ne zaman?" tarzı süzgeçler için ortak eşleşme — geçmiş günler asla
/// dahil edilmez (hafta sonu tuzağı: negatif `difference.inDays < 14`).
enum BrowseWhen { any, tonight, tomorrow, weekend, week }

DateTime browseDay(final DateTime d) => DateTime(d.year, d.month, d.day);

/// Yaklaşan Cumartesi–Pazar (bugünden itibaren kalan günler). Geçmiş
/// Cumartesi/Pazar veya sonraki hafta sonu dahil değil.
bool browseIsUpcomingWeekend(final DateTime date, {final DateTime? now}) {
  final DateTime n = now ?? DateTime.now();
  final DateTime today = browseDay(n);
  final DateTime day = browseDay(date);
  if (day.isBefore(today)) {
    return false;
  }
  if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
    return false;
  }
  final int daysToSunday = (DateTime.sunday - today.weekday + 7) % 7;
  final DateTime weekendEnd = today.add(Duration(days: daysToSunday));
  final DateTime weekendStart = weekendEnd.subtract(const Duration(days: 1));
  return !day.isBefore(today) &&
      !day.isAfter(weekendEnd) &&
      !day.isBefore(weekendStart);
}

bool browseMatchesWhen(
  final DateTime date,
  final BrowseWhen when, {
  final DateTime? now,
}) {
  if (when == BrowseWhen.any) {
    return true;
  }
  final DateTime n = now ?? DateTime.now();
  final DateTime today = browseDay(n);
  final DateTime day = browseDay(date);
  switch (when) {
    case BrowseWhen.any:
      return true;
    case BrowseWhen.tonight:
      return day == today && !date.isBefore(n);
    case BrowseWhen.tomorrow:
      return day == today.add(const Duration(days: 1));
    case BrowseWhen.weekend:
      return browseIsUpcomingWeekend(date, now: n) && !date.isBefore(n);
    case BrowseWhen.week:
      return !date.isBefore(n) && day.difference(today).inDays < 7;
  }
}

/// Tek seçimli çip grubu — [ListingChip] + [Reveal]. [wrap] true → satır
/// atlayan grup; false → fareyle de sürüklenebilen yatay şerit.
class BrowseChoiceChips extends StatelessWidget {
  final List<BrowseOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool wrap;
  final EdgeInsetsGeometry padding;
  final bool reveal;

  const BrowseChoiceChips({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.wrap = false,
    this.padding = EdgeInsets.zero,
    this.reveal = true,
  });

  Widget _chip(final int i) {
    final BrowseOption o = options[i];
    final Widget chip = ListingChip(
      label: o.label,
      count: o.count,
      icon: o.icon,
      selected: i == selectedIndex,
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(i);
      },
    );
    if (!reveal) {
      return chip;
    }
    return Reveal(index: i.clamp(0, 8), child: chip);
  }

  @override
  Widget build(final BuildContext context) {
    if (wrap) {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (int i = 0; i < options.length; i++) _chip(i),
          ],
        ),
      );
    }
    return SizedBox(
      height: 56,
      child: ScrollConfiguration(
        behavior: const BrowseDragScrollBehavior(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: padding,
          itemCount: options.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(width: AppSpacing.md),
          itemBuilder: (final context, final i) =>
              Center(child: _chip(i)),
        ),
      ),
    );
  }
}

/// "Sahnede" / "Geçmiş" anahtarı — iki eşit parçalı, sade bir segment
/// kontrol. Klavyeyle erişilebilir, seçili parça temanın vurgusuyla dolar.
/// Verilen genişliği doldurur — sınırlı bir genişlik içinde kullanılmalı.
class ShowsModeToggle extends StatelessWidget {
  final bool showPast;
  final ValueChanged<bool> onChanged;

  const ShowsModeToggle({
    super.key,
    required this.showPast,
    required this.onChanged,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSegment(
              label: 'Sahnede',
              selected: !showPast,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ModeSegment(
              label: 'Geçmiş',
              selected: showPast,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label == 'Geçmiş' ? 'Geçmiş oyunlar' : 'Sahnedeki oyunlar',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          focusColor: cs.primary.withValues(alpha: 0.2),
          hoverColor: cs.onSurface.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Masaüstü kenar çubuğundaki dikey seçenek satırı (kategori, arama türü).
class BrowseSideOption extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? tone;
  final Color? toneInk;

  const BrowseSideOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.icon,
    this.tone,
    this.toneInk,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool tinted = tone != null && toneInk != null;
    final Color fg =
        selected ? cs.onPrimary : (tinted ? toneInk! : cs.onSurface);
    final Color meta = selected
        ? cs.onPrimary.withValues(alpha: 0.8)
        : (tinted ? toneInk!.withValues(alpha: 0.75) : cs.onSurfaceVariant);
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : '$label, $count',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? (tinted ? cs.primary : cs.primary.withValues(alpha: 0.1))
            : (tinted ? tone! : Colors.transparent),
        borderRadius:
            BorderRadius.circular(tinted ? AppRadius.md : AppRadius.xs),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          focusColor: cs.primary.withValues(alpha: 0.18),
          hoverColor: cs.onSurface.withValues(alpha: 0.05),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: tinted ? 48 : 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: 18,
                        color: tinted
                            ? fg
                            : (selected ? cs.primary : cs.onSurfaceVariant)),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tinted
                            ? fg
                            : (selected ? cs.primary : cs.onSurface),
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  if (count != null)
                    Text(
                      '$count',
                      style: TextStyle(
                        color: meta,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

/// Kenar çubuğu grup etiketi ("Görünüm", "Kategori").
class BrowseSideLabel extends StatelessWidget {
  final String text;
  const BrowseSideLabel(this.text, {super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            left: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Kişi / mekan satırı ve yapışkan başlık
// ─────────────────────────────────────────────────────────────────────────

/// Sahne, topluluk gibi "yer/kişi" sonuçları için sade liste satırı —
/// bunlar bilet değildir, bilet diliyle süslenmez.
class BrowseListTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const BrowseListTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.fallbackIcon = Icons.theater_comedy_rounded,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    return Semantics(
      button: true,
      label: hasSubtitle ? '$title, ${subtitle!}' : title,
      excludeSemantics: true,
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          focusColor: cs.primary.withValues(alpha: 0.16),
          hoverColor: cs.onSurface.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: OptimizedCachedImage(
                    imageUrl: imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    borderRadius: AppRadius.xs,
                    errorBuilder: (final _, final __, final ___) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Icon(fallbackIcon, color: cs.primary, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobil/tablette kaydırırken üstte kalan filtre şeridi. Opak tema zemini
/// (bulanıklık/glassmorphism yok); içerik altına girince ince bir çizgi.
class PinnedBrowseHeader extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  PinnedBrowseHeader({required this.extent, required this.child});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(final BuildContext context, final double shrinkOffset,
      final bool overlapsContent) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: overlapsContent ? cs.outlineVariant : Colors.transparent,
            ),
          ),
        ),
        child: SizedBox.expand(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant final PinnedBrowseHeader oldDelegate) => true;
}

/// Değişken yükseklikli öğeleri genişliğe göre sütunlara dizen sade ızgara
/// (sütun sayısı = kaç tane [minItemWidth] sığıyorsa; sabit sayı yok).
/// Kısa listeler (≤ ~30 öğe) için — uzun listelerde `SliverGrid` kullan.
class BrowseColumns extends StatelessWidget {
  final double minItemWidth;
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const BrowseColumns({
    super.key,
    required this.minItemWidth,
    required this.children,
    this.spacing = AppSpacing.lg,
    this.runSpacing = AppSpacing.md,
  });

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          final double width = constraints.maxWidth;
          final int columns =
              ((width + spacing) / (minItemWidth + spacing))
                  .floor()
                  .clamp(1, 6)
                  .toInt();
          final double itemWidth = (width - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: [
              for (final child in children)
                SizedBox(width: itemWidth, child: child),
            ],
          );
        },
      );
}

/// Yatay kaydırılan şerit (mobil) — fareyle de sürüklenebilir.
class BrowseRail extends StatelessWidget {
  final double height;
  final double itemWidth;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  const BrowseRail({
    super.key,
    required this.height,
    required this.itemWidth,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: height,
        child: ScrollConfiguration(
          behavior: const BrowseDragScrollBehavior(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: children.length,
            separatorBuilder: (final _, final __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (final context, final i) =>
                SizedBox(width: itemWidth, child: children[i]),
          ),
        ),
      );
}

/// Oyun kartı (`TheatreShowCard`) ızgarası — sütun sayısı genişlikten
/// türer, sabit `crossAxisCount` yok.
SliverGridDelegate browseShowGridDelegate(final double maxCardWidth) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCardWidth,
      mainAxisSpacing: AppSpacing.xl,
      crossAxisSpacing: AppSpacing.lg,
      childAspectRatio: 0.6,
    );

/// Sabit yükseklikli satır ızgarası (sahne/topluluk satırları, seanslar).
SliverGridDelegate browseRowGridDelegate(
        {required final double maxRowWidth, required final double rowHeight}) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxRowWidth,
      mainAxisExtent: rowHeight,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.lg,
    );

/// Türkçe büyük/küçük harf ve boşluk farkını yok sayan tür anahtarı.
String browseCategoryKey(final String raw) => raw
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll('İ', 'i')
    .replaceAll('I', 'ı')
    .toLowerCase();

class BrowseCategory {
  final String key;
  final String label;
  final int count;
  final String imageUrl;

  const BrowseCategory(this.key, this.label, this.count, this.imageUrl);
}

List<BrowseCategory> browseCategoriesOf(final List<Show> shows) {
  final Map<String, Map<String, int>> spellings = {};
  final Map<String, List<Show>> byKey = {};
  for (final Show show in shows) {
    final String raw = show.category.trim();
    if (raw.isEmpty) {
      continue;
    }
    final String key = browseCategoryKey(raw);
    byKey.putIfAbsent(key, () => []).add(show);
    final Map<String, int> spelling = spellings.putIfAbsent(key, () => {});
    spelling[raw] = (spelling[raw] ?? 0) + 1;
  }
  final List<BrowseCategory> list = byKey.entries.map((final entry) {
    final Map<String, int> spelling = spellings[entry.key]!;
    final String label = (spelling.entries.toList()
          ..sort((final a, final b) => b.value.compareTo(a.value)))
        .first
        .key;
    final String image = entry.value
        .map((final show) => show.imageUrl.trim())
        .firstWhere((final url) => url.isNotEmpty, orElse: () => '');
    return BrowseCategory(entry.key, label, entry.value.length, image);
  }).toList()
    ..sort((final a, final b) {
      final int byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.label.compareTo(b.label);
    });
  return list;
}

/// Keşfet'teki kayan tür şeridi. Dokununca süzer, tekrar dokununca Tümü.
class BrowseCategoryStrip extends StatelessWidget {
  final List<BrowseCategory> categories;
  final String? selectedKey;
  final int total;
  final ValueChanged<String?> onPick;
  final EdgeInsets padding;

  const BrowseCategoryStrip({
    super.key,
    required this.categories,
    required this.selectedKey,
    required this.total,
    required this.onPick,
    required this.padding,
  });

  @override
  Widget build(final BuildContext context) {
    if (categories.length < 2) {
      return const SizedBox.shrink();
    }
    final List<BrowseCategory> all = [
      BrowseCategory('', 'Tümü', total, ''),
      ...categories,
    ];
    return ScrollConfiguration(
      behavior: const BrowseDragScrollBehavior(),
      child: SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: all.length,
          separatorBuilder: (final _, final __) =>
              const SizedBox(width: AppSpacing.md),
          itemBuilder: (final context, final i) {
            final BrowseCategory category = all[i];
            final bool isAll = category.key.isEmpty;
            return Reveal(
              index: i.clamp(0, 8),
              child: _BrowseCategoryCard(
                label: category.label,
                count: category.count,
                imageUrl: category.imageUrl,
                selected: isAll
                    ? selectedKey == null
                    : selectedKey == category.key,
                onTap: () => onPick(isAll ? null : category.key),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrowseCategoryCard extends StatelessWidget {
  final String label;
  final int count;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _BrowseCategoryCard({
    required this.label,
    required this.count,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasImage = imageUrl.trim().isNotEmpty;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count oyun',
      excludeSemantics: true,
      child: PressScale(
        label: '$label, $count oyun',
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 136,
          height: 104,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 2.4,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg - 2),
            child: ColoredBox(
              color: hasImage ? Colors.black : cs.primaryContainer,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Opacity(
                      opacity: selected ? 0.92 : 0.62,
                      child: OptimizedCachedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                    ),
                  if (hasImage)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x11000000), Color(0xCC000000)],
                        ),
                      ),
                    ),
                  if (selected)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Icon(Icons.check_circle_rounded,
                          size: 20, color: cs.primary),
                    ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: hasImage
                                ? Colors.white
                                : cs.onPrimaryContainer,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$count oyun',
                          style: listingUi(
                            color: hasImage
                                ? const Color(0xCCFFFFFF)
                                : cs.onPrimaryContainer.withValues(alpha: 0.8),
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
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
