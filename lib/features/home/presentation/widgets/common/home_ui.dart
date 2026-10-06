import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/ticket/theatre_bubbles.dart';
import '../../../../../shared/widgets/ticket/ticket_search.dart';

import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../stages/domain/entities/stage.dart';

/// Ana sayfanın (web + mobil) ortak, TEMAYA bağlı yapı taşları: bölüm
/// başlığı, arama alanı, fare ile sürüklenebilen yatay şerit, kampanya ve
/// sahne kartları. Renkler her zaman `Theme.of(context).colorScheme`'dan —
/// 5 tema (açık/koyu/Material You/özel vurgu) burada da geçerli. Kağıt/
/// mürekkep (bilet) parçaları ayrı dosyada: `home_ticket_widgets.dart`.

/// Yeni eklenen kısa metinler için basit TR/EN seçimi (ARB'ye eklemek
/// gen-l10n gerektiriyor; bu sandbox'ta Flutter SDK yok).
String homeText(
        final BuildContext context, final String tr, final String en) =>
    Localizations.localeOf(context).languageCode == 'tr' ? tr : en;

/// CSS `clamp()` karşılığı: ekran genişliğine göre [min]–[max] arası.
double homeFluid(final BuildContext context, final double min,
    final double max,
    {final double minW = 375, final double maxW = 1440}) {
  final double w = MediaQuery.sizeOf(context).width;
  final double t = ((w - minW) / (maxW - minW)).clamp(0.0, 1.0);
  return min + (max - min) * t;
}

/// Bölüm başlığı: Playfair başlık + (varsa) sağda tek metin bağlantısı.
/// Başlığın üstünde "eyebrow" etiketi yok.
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: cs.onSurface,
                fontSize: homeFluid(context, 22, 34),
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: AppSpacing.md),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ana sayfanın arama düğmesi. Dokununca yüzen damga balonları açılır
/// (Ara / Yakınımda / Keşfet / Kampanya); azaltılmış harekette doğrudan arama.
class HomeSearchField extends StatelessWidget {
  final VoidCallback onTap;
  final String hint;
  final bool compact;

  const HomeSearchField({
    super.key,
    required this.onTap,
    required this.hint,
    this.compact = false,
  });

  @override
  Widget build(final BuildContext context) => TicketSearchButton(
        onTap: () => showTheatreBubbles(
          origin: context,
          onSkip: onTap,
          actions: [
            TheatreBubbleAction(
              label: homeText(context, 'Ara', 'Search'),
              icon: Icons.search_rounded,
              onTap: onTap,
            ),
            TheatreBubbleAction(
              label: homeText(context, 'Yakınımda', 'Nearby'),
              icon: Icons.near_me_rounded,
              onTap: () => NavigationHandler.goToNearby(context),
            ),
            TheatreBubbleAction(
              label: homeText(context, 'Keşfet', 'Discover'),
              icon: Icons.theater_comedy_rounded,
              onTap: () => NavigationHandler.goToDiscover(context),
            ),
            TheatreBubbleAction(
              label: homeText(context, 'Kampanya', 'Offers'),
              icon: Icons.local_activity_outlined,
              onTap: () => NavigationHandler.goToCampaigns(context),
            ),
          ],
        ),
        semanticLabel: hint,
        compact: compact,
      );
}

/// Yatay şerit: dokunma + FARE + trackpad ile sürüklenir; [showArrows]
/// (masaüstü) açıkken iki yanda, kaydırılabilecek yön varsa görünen ok
/// butonları (klavye ile de erişilebilir). Azaltılmış harekette oklar
/// animasyonsuz atlar.
class HomeRail extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;
  final double height;
  final double gap;
  final bool showArrows;
  final EdgeInsetsGeometry padding;

  const HomeRail({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemWidth,
    required this.height,
    this.gap = AppSpacing.lg,
    this.showArrows = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<HomeRail> createState() => _HomeRailState();
}

class _HomeRailState extends State<HomeRail> {
  final ScrollController _controller = ScrollController();
  bool _canBack = false;
  bool _canForward = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((final _) => _sync());
  }

  @override
  void didUpdateWidget(covariant final HomeRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((final _) => _sync());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final bool back = pos.pixels > pos.minScrollExtent + 1;
    final bool forward = pos.pixels < pos.maxScrollExtent - 1;
    if (back != _canBack || forward != _canForward)
      setState(() {
        _canBack = back;
        _canForward = forward;
      });
  }

  void _page(final int direction) {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final double target = (pos.pixels + direction * pos.viewportDimension * 0.8)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if (MediaQuery.of(context).disableAnimations)
      _controller.jumpTo(target);
    else
      _controller.animateTo(target,
          duration: AppMotion.normal, curve: AppMotion.standard);
  }

  @override
  Widget build(final BuildContext context) {
    final Widget list = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: const {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.itemCount,
        separatorBuilder: (final _, final __) => SizedBox(width: widget.gap),
        itemBuilder: (final context, final index) => SizedBox(
          width: widget.itemWidth,
          child: widget.itemBuilder(context, index),
        ),
      ),
    );

    return SizedBox(
      height: widget.height,
      child: !widget.showArrows
          ? list
          : Stack(
              children: [
                Positioned.fill(child: list),
                if (_canBack)
                  Positioned(
                    left: AppSpacing.sm,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _RailArrow(
                        icon: Icons.chevron_left_rounded,
                        tooltip: homeText(context, 'Geri kaydır', 'Scroll back'),
                        onTap: () => _page(-1),
                      ),
                    ),
                  ),
                if (_canForward)
                  Positioned(
                    right: AppSpacing.sm,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _RailArrow(
                        icon: Icons.chevron_right_rounded,
                        tooltip:
                            homeText(context, 'İleri kaydır', 'Scroll forward'),
                        onTap: () => _page(1),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RailArrow extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RailArrow(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 26),
      style: IconButton.styleFrom(
        backgroundColor: cs.surfaceContainerHighest,
        foregroundColor: cs.onSurface,
        hoverColor: cs.primary.withOpacity(0.10),
        focusColor: cs.primary.withOpacity(0.18),
        minimumSize: const Size(48, 48),
        side: BorderSide(color: cs.outlineVariant),
        elevation: 2,
        shadowColor: cs.shadow,
      ),
    );
  }
}

/// Görselli, tıklanabilir kart çatısı: görselin ÜSTÜNDE görünen hover/klavye
/// odak çerçevesi (InkWell'in kendi vurgusu görselin altında kalıyordu).
class HomeTappableCard extends StatefulWidget {
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  const HomeTappableCard({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  @override
  State<HomeTappableCard> createState() => _HomeTappableCardState();
}

class _HomeTappableCardState extends State<HomeTappableCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    final Color ring = _focused
        ? cs.primary
        : (_hovered ? cs.outline : Colors.transparent);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (final v) => setState(() => _hovered = v),
          onFocusChange: (final v) => setState(() => _focused = v),
          mouseCursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: ring, width: _focused ? 2.5 : 1.5),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Kampanya kartı (gerçek `Campaign`): görsel + başlık.
class HomeCampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const HomeCampaignCard(
      {super.key, required this.campaign, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return HomeTappableCard(
      semanticLabel: campaign.title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: OptimizedCachedImage(
              imageUrl: campaign.imageUrl,
              fit: BoxFit.cover,
              borderRadius: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              campaign.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sahne kartı (gerçek `Stage`): fotoğraf + ad + (varsa) kapasite.
class HomeStageCard extends StatelessWidget {
  final Stage stage;
  final VoidCallback onTap;

  const HomeStageCard({super.key, required this.stage, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String capacity = stage.capacity.trim();
    final String capacityLabel = capacity.isEmpty || capacity == '0'
        ? ''
        : homeText(context, '$capacity kişilik', '$capacity seats');
    return HomeTappableCard(
      semanticLabel:
          capacityLabel.isEmpty ? stage.name : '${stage.name}, $capacityLabel',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: OptimizedCachedImage(
              imageUrl: stage.imageUrl,
              fit: BoxFit.cover,
              borderRadius: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stage.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (capacityLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    capacityLabel,
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
        ],
      ),
    );
  }
}
