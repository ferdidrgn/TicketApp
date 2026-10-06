import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/common/enum/enums.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';

/// Ayarlar + Profil sayfalarının ortak, TEMAYA bağlı yapı taşları:
/// sayfa başlığı, bölüm başlığı, gruplanmış satırlar, dil seçici ve
/// sahibinin en sevdiği özellik — tema stili seçici + özel vurgu rengi.
///
/// Renkler her zaman `Theme.of(context).colorScheme`'dan; 5 tema (+ özel
/// vurgu) burada da geçerli. Gölgeli eş kartlar yok: satırlar tek bir
/// çerçeveli grup içinde, aralarında ince çizgi.

/// Yeni eklenen kısa metinler için TR/EN seçimi (ARB'ye eklemek gen-l10n
/// gerektiriyor; bu sandbox'ta Flutter SDK yok).
String prefText(
        final BuildContext context, final String tr, final String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : tr;

/// CSS `clamp()` karşılığı: ekran genişliğine göre [min]–[max] arası.
double prefFluid(final BuildContext context, final double min,
    final double max,
    {final double minW = 375, final double maxW = 1440}) {
  final double w = MediaQuery.sizeOf(context).width;
  final double t = ((w - minW) / (maxW - minW)).clamp(0.0, 1.0);
  return min + (max - min) * t;
}

// ─────────────────────────────────────────────────────────────────────────
// Başlıklar
// ─────────────────────────────────────────────────────────────────────────

/// Sayfa başlığı: Playfair + soldan sağa perde açılışı (onaylanan wipe).
/// [onBack] verilirse solda 48dp geri butonu (kendi Scaffold'unu kuran
/// masaüstü sayfaları için).
class PreferencePageHeading extends StatefulWidget {
  final String title;
  final String? lede;
  final VoidCallback? onBack;

  const PreferencePageHeading({
    super.key,
    required this.title,
    this.lede,
    this.onBack,
  });

  @override
  State<PreferencePageHeading> createState() => _PreferencePageHeadingState();
}

class _PreferencePageHeadingState extends State<PreferencePageHeading>
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
    final Widget text = Column(
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
                fontSize: prefFluid(context, 32, 48),
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
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              widget.lede!,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ],
    );

    if (widget.onBack == null) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: prefText(context, 'Geri', 'Back'),
          onPressed: widget.onBack,
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: text),
      ],
    );
  }
}

/// Bölüm başlığı: Playfair, üstünde "eyebrow" etiketi yok.
class PreferenceSectionTitle extends StatelessWidget {
  final String title;
  final String? caption;

  const PreferenceSectionTitle(this.title, {super.key, this.caption});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: cs.onSurface,
                fontSize: prefFluid(context, 21, 26),
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const TicketInkHairline(strong: 0.38, soft: 0.22),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Gruplanmış satırlar
// ─────────────────────────────────────────────────────────────────────────

/// Satırları tek bir çerçeveli yüzeyde toplar (her satır ayrı gölgeli kart
/// değil), aralarına ince çizgi koyar.
class PreferenceGroup extends StatelessWidget {
  final List<Widget> children;

  const PreferenceGroup({super.key, required this.children});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.lg + 22 + AppSpacing.lg,
                color: cs.outlineVariant,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Tek satır: ikon + başlık (+ açıklama) + sağda ok / kilit / özel öğe.
/// [destructive] → temanın `error` rengi (hesabı sil gibi).
class PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool locked;
  final bool destructive;

  const PreferenceRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.locked = false,
    this.destructive = false,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color tone = destructive ? cs.error : cs.onSurface;
    final Color iconTone = destructive ? cs.error : cs.onSurfaceVariant;

    return Semantics(
      button: onTap != null,
      label: [
        title,
        if (subtitle != null) subtitle!,
        if (locked) prefText(context, 'giriş gerekli', 'sign-in required'),
      ].join('. '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        mouseCursor:
            onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        hoverColor: cs.onSurface.withOpacity(0.04),
        focusColor: cs.primary.withOpacity(0.14),
        highlightColor: cs.onSurface.withOpacity(0.06),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconTone),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: tone,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                trailing ??
                    Icon(
                      locked
                          ? Icons.lock_outline_rounded
                          : Icons.chevron_right_rounded,
                      size: locked ? 18 : 22,
                      color: cs.onSurfaceVariant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Dil
// ─────────────────────────────────────────────────────────────────────────

/// İki seçenekli dil anahtarı (Türkçe / İngilizce). 48dp yükseklik,
/// klavyeyle erişilebilir, seçili olan temanın vurgu renginde.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final String code =
        ref.watch(localeControllerProvider).value?.languageCode ?? 'tr';
    void select(final String c) =>
        ref.read(localeControllerProvider.notifier).setLocale(Locale(c));

    return _Segmented(
      options: [
        (value: 'tr', label: l10n.settingsLanguageTurkish),
        (value: 'en', label: l10n.settingsLanguageEnglish),
      ],
      selected: code,
      onSelect: select,
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<({String value, String label})> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _Segmented({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: o.value == selected,
                inMutuallyExclusiveGroup: true,
                label: o.label,
                excludeSemantics: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => onSelect(o.value),
                    borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                    focusColor: cs.primary.withOpacity(0.2),
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.standard,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: o.value == selected
                            ? cs.primary
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm - 2),
                      ),
                      child: Text(
                        o.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: o.value == selected
                              ? cs.onPrimary
                              : cs.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: o.value == selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tema stili seçici (5 tema + Özel)
// ─────────────────────────────────────────────────────────────────────────

class _StyleInfo {
  final String tr, en, descTr, descEn;
  final IconData icon;
  const _StyleInfo(this.tr, this.en, this.descTr, this.descEn, this.icon);
}

const Map<AppThemeStyle, _StyleInfo> _styleInfo = {
  AppThemeStyle.appLight: _StyleInfo('Gündüz', 'Day',
      'Açık zemin, TiyatRol kırmızısı', 'Light, TiyatRol red',
      Icons.wb_sunny_rounded),
  AppThemeStyle.appDark: _StyleInfo('Gece', 'Night',
      'Koyu zemin, göz yormaz', 'Dark, easy on the eyes',
      Icons.nights_stay_rounded),
  AppThemeStyle.system: _StyleInfo('Oto', 'Auto',
      'Cihazının açık/koyu ayarını izler', 'Follows your device',
      Icons.auto_mode_rounded),
  AppThemeStyle.materialLight: _StyleInfo('Doğa', 'Nature',
      'Duvar kağıdının renkleri, açık', 'Wallpaper colours, light',
      Icons.palette_outlined),
  AppThemeStyle.materialDark: _StyleInfo('Ahenk', 'Harmony',
      'Duvar kağıdının renkleri, koyu', 'Wallpaper colours, dark',
      Icons.blur_on_rounded),
  AppThemeStyle.custom: _StyleInfo('Özel', 'Custom',
      'Seçtiğin renk; cihaza göre açık/koyu', 'Your colour, light or dark',
      Icons.colorize_rounded),
};

String themeStyleLabel(final BuildContext context, final AppThemeStyle s) =>
    prefText(context, _styleInfo[s]!.tr, _styleInfo[s]!.en);

/// Bir temanın küçük önizlemesi için renkler — `ThemeManager`'ın aynı
/// tohumlarından (`ColorScheme.fromSeed`) türetilir. Bölünmüş (`bg2`)
/// önizleme: cihaza göre açık/koyu değişen stiller.
class _Preview {
  final Color bg, ink, accent;
  final Color? bg2, ink2, accent2;
  const _Preview(this.bg, this.ink, this.accent,
      {this.bg2, this.ink2, this.accent2});
}

final Map<String, _Preview> _previewCache = {};

_Preview _previewFor(final AppThemeStyle style, final Color? customColor,
    final Color materialSeed) {
  final String key =
      '${style.name}-${customColor?.value}-${materialSeed.value}';
  return _previewCache.putIfAbsent(key, () {
    const Color red = AppLightColors.primary;
    ColorScheme light(final Color seed) =>
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    ColorScheme dark(final Color seed) =>
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    _Preview split(final Color seed) {
      final l = light(seed), d = dark(seed);
      return _Preview(l.surface, l.onSurface, l.primary,
          bg2: d.surface, ink2: d.onSurface, accent2: d.primary);
    }

    switch (style) {
      case AppThemeStyle.appLight:
        final s = light(red);
        return _Preview(s.surface, s.onSurface, s.primary);
      case AppThemeStyle.appDark:
        const s = ColorScheme.dark();
        return _Preview(s.surface, s.onSurface, s.primary);
      case AppThemeStyle.system:
        return split(red);
      case AppThemeStyle.materialLight:
        final s = light(materialSeed);
        return _Preview(s.surface, s.onSurface, s.primary);
      case AppThemeStyle.materialDark:
        final s = dark(materialSeed);
        return _Preview(AppTheme.createAtmosphericBackground(materialSeed),
            Colors.white, s.primary);
      case AppThemeStyle.custom:
        return split(customColor ?? red);
    }
  });
}

/// Sahibinin en sevdiği özellik: 5 tema + Özel. Her seçenek, o temanın
/// GERÇEK zemin/vurgu renkleriyle küçük bir ekran önizlemesi gösterir —
/// eski hâlinde sadece seçili olanın adı görünüyordu.
///
/// [compact] → tek satır, 6 yuvarlak önizleme + ad (profil, mobil).
/// Değilse → 2–3 sütunlu önizleme kutuları + açıklama (ayarlar).
class ThemeStylePicker extends ConsumerWidget {
  final bool compact;

  const ThemeStylePicker({super.key, this.compact = false});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppThemeStyle current = ref.watch(themeProvider);
    final Color? custom = ref.watch(customAccentColorProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;
    // Duvar kağıdı rengi sadece Material stilleri aktifken biliniyor
    // (web'de hiç yok) — yoksa uygulamanın varsayılan tohumu.
    final bool materialActive = current == AppThemeStyle.materialLight ||
        current == AppThemeStyle.materialDark;
    final Color materialSeed =
        materialActive ? cs.primary : AppLightColors.primary;

    void select(final AppThemeStyle s) =>
        ref.read(themeProvider.notifier).setTheme(s);

    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in AppThemeStyle.values)
            Expanded(
              child: _ThemeChip(
                style: s,
                selected: s == current,
                preview: _previewFor(s, custom, materialSeed),
                onTap: () => select(s),
              ),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (final context, final c) {
        final int cols = c.maxWidth >= 520 ? 3 : 2;
        const double gap = AppSpacing.md;
        final double w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in AppThemeStyle.values)
              SizedBox(
                width: w,
                child: _ThemeTile(
                  style: s,
                  selected: s == current,
                  preview: _previewFor(s, custom, materialSeed),
                  onTap: () => select(s),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Önizleme: temanın zemini, üstünde metin çizgisi ve vurgu şeridi.
/// Bölünmüşse sol yarı açık, sağ yarı koyu.
class _PreviewSwatch extends StatelessWidget {
  final _Preview p;
  final bool circle;

  const _PreviewSwatch({required this.p, this.circle = false});

  Widget _half(final Color bg, final Color ink, final Color accent) =>
      ColoredBox(
        color: bg,
        child: Padding(
          padding: EdgeInsets.all(circle ? 7 : AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: 0.8,
                child: Container(height: 3, color: ink.withOpacity(0.35)),
              ),
              SizedBox(height: circle ? 3 : 5),
              FractionallySizedBox(
                widthFactor: 0.55,
                child: Container(
                  height: circle ? 5 : 7,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(final BuildContext context) {
    final Widget body = p.bg2 == null
        ? _half(p.bg, p.ink, p.accent)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _half(p.bg, p.ink, p.accent)),
              Expanded(child: _half(p.bg2!, p.ink2!, p.accent2!)),
            ],
          );
    final BorderSide edge =
        BorderSide(color: Theme.of(context).colorScheme.outlineVariant);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: circle
          ? BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(edge))
          : BoxDecoration(
              border: Border.fromBorderSide(edge),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
      child: circle
          ? ClipOval(child: body)
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: body,
            ),
    );
  }
}

/// Hover + klavye odağı durumunu çocuğa veren dokunma kabuğu.
class _Pressable extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final BorderRadius radius;
  final Widget Function(bool hovered, bool focused) builder;

  const _Pressable({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.radius,
    required this.builder,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        selected: widget.selected,
        inMutuallyExclusiveGroup: true,
        label: widget.label,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (final v) => setState(() => _hovered = v),
            onFocusChange: (final v) => setState(() => _focused = v),
            borderRadius: widget.radius,
            mouseCursor: SystemMouseCursors.click,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: widget.builder(_hovered, _focused),
          ),
        ),
      );
}

class _ThemeTile extends StatelessWidget {
  final AppThemeStyle style;
  final bool selected;
  final _Preview preview;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.style,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _StyleInfo info = _styleInfo[style]!;
    final String label = prefText(context, info.tr, info.en);
    final String desc = prefText(context, info.descTr, info.descEn);
    final BorderRadius radius = BorderRadius.circular(AppRadius.sm);

    return _Pressable(
      label: '$label. $desc',
      selected: selected,
      onTap: onTap,
      radius: radius,
      builder: (final hovered, final focused) => AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withOpacity(0.45)
              : (hovered ? cs.surfaceContainerHigh : cs.surfaceContainerLow),
          borderRadius: radius,
          border: Border.all(
            color: selected || focused ? cs.primary : cs.outlineVariant,
            width: selected || focused ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 60, child: _PreviewSwatch(p: preview)),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                Icon(info.icon, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: AppMotion.fast,
                  child: Icon(Icons.check_circle_rounded,
                      size: 18, color: cs.primary),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final AppThemeStyle style;
  final bool selected;
  final _Preview preview;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.style,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _StyleInfo info = _styleInfo[style]!;
    final String label = prefText(context, info.tr, info.en);
    return _Pressable(
      label: '$label. ${prefText(context, info.descTr, info.descEn)}',
      selected: selected,
      onTap: onTap,
      radius: BorderRadius.circular(AppRadius.sm),
      builder: (final hovered, final focused) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected || focused
                      ? cs.primary
                      : (hovered ? cs.outline : Colors.transparent),
                  width: 2,
                ),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: _PreviewSwatch(p: preview, circle: true),
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? cs.onSurface : cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Özel vurgu rengi
// ─────────────────────────────────────────────────────────────────────────

/// Hazır vurgu renkleri (önceden Ayarlar'daki diyalogdaydı; artık sayfada,
/// tek dokunuşla). Seçim `ThemeNotifier.setCustomAccentColor` ile yapılır:
/// renk kaydedilir ve tema otomatik "Özel"e geçer.
const List<({Color color, String tr, String en})> accentColorPresets = [
  (color: Color(0xFFC50337), tr: 'Kızıl', en: 'Crimson'),
  (color: Color(0xFF9C27B0), tr: 'Kadife mor', en: 'Velvet purple'),
  (color: Color(0xFF3F51B5), tr: 'Sahne mavisi', en: 'Stage blue'),
  (color: Color(0xFF009688), tr: 'Kulis yeşili', en: 'Backstage green'),
  (color: Color(0xFFFF9800), tr: 'Sahne ışığı amber', en: 'Stage-light amber'),
  (color: Color(0xFFE91E63), tr: 'Perde pembesi', en: 'Curtain pink'),
  (color: Color(0xFF795548), tr: 'Tahta sahne kahvesi', en: 'Wooden brown'),
  (color: Color(0xFF607D8B), tr: 'Fırtına grisi', en: 'Storm grey'),
  (color: Color(0xFFFF5722), tr: 'Kırmızı turuncu', en: 'Red orange'),
  (color: Color(0xFF673AB7), tr: 'Derin gece moru', en: 'Deep night purple'),
];

class AccentColorPalette extends ConsumerWidget {
  const AccentColorPalette({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool customActive = ref.watch(themeProvider) == AppThemeStyle.custom;
    final Color? current = ref.watch(customAccentColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.settingsAccentColorTitle,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          customActive && current != null
              ? l10n.settingsAccentColorCustomSubtitle
              : '${l10n.settingsAccentColorDefaultSubtitle} '
                  '${prefText(context, 'Seçince tema "Özel"e geçer.', 'Picking one switches to "Custom".')}',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final p in accentColorPresets)
              _AccentSwatch(
                color: p.color,
                name: prefText(context, p.tr, p.en),
                selected: customActive && current?.value == p.color.value,
                onTap: () => ref
                    .read(themeProvider.notifier)
                    .setCustomAccentColor(p.color),
              ),
          ],
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color check =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Tooltip(
      message: name,
      child: _Pressable(
        label:
            '$name. ${AppLocalizations.of(context)!.settingsAccentColorSemanticLabel}',
        selected: selected,
        onTap: onTap,
        radius: BorderRadius.circular(AppRadius.pill),
        builder: (final hovered, final focused) => SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected || focused
                      ? cs.onSurface
                      : (hovered ? cs.outline : Colors.transparent),
                  width: 2,
                ),
              ),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: selected
                    ? Icon(Icons.check_rounded, size: 18, color: check)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
