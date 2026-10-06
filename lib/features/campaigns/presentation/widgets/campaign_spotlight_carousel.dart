import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../domain/entities/campaign.dart';
import 'campaign_coupon.dart';

/// Kampanya vitrini — ana sayfadaki [HomeSpotlightCarousel] ile aynı etkileşim:
/// otomatik slayt, altta dolan ilerleme noktaları, dokununca durur.
class CampaignSpotlightCarousel extends StatefulWidget {
  final List<Campaign> campaigns;
  final int initialIndex;

  /// Dış seçim (ör. tablet liste satırı) ile sayfayı eşitlemek için.
  final int? activeIndex;
  final ValueChanged<int> onIndexChanged;
  final double? height;
  final EdgeInsets padding;

  const CampaignSpotlightCarousel({
    super.key,
    required this.campaigns,
    required this.onIndexChanged,
    this.initialIndex = 0,
    this.activeIndex,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  @override
  State<CampaignSpotlightCarousel> createState() =>
      _CampaignSpotlightCarouselState();
}

class _CampaignSpotlightCarouselState extends State<CampaignSpotlightCarousel>
    with SingleTickerProviderStateMixin {
  static const Duration _dwell = Duration(seconds: 5);

  late final PageController _page;
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: _dwell)
        ..addStatusListener((final s) {
          if (s == AnimationStatus.completed) _next();
        });
  late int _index;
  bool _auto = true;

  @override
  void initState() {
    super.initState();
    final int max = widget.campaigns.length;
    _index = max == 0 ? 0 : widget.initialIndex.clamp(0, max - 1);
    _page = PageController(initialPage: _index);
  }

  @override
  void didUpdateWidget(covariant final CampaignSpotlightCarousel old) {
    super.didUpdateWidget(old);
    final int max = widget.campaigns.length;
    if (max == 0) return;

    if (widget.campaigns.length != old.campaigns.length && _page.hasClients) {
      final int safe = _index.clamp(0, max - 1);
      if (safe != _index) {
        _index = safe;
        _page.jumpToPage(safe);
        widget.onIndexChanged(safe);
      }
    }

    final int? external = widget.activeIndex;
    if (external != null &&
        external != _index &&
        external != old.activeIndex &&
        _page.hasClients) {
      final int safe = external.clamp(0, max - 1);
      _index = safe;
      _page.jumpToPage(safe);
      if (_auto && widget.campaigns.length > 1) {
        _progress.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auto = !MediaQuery.of(context).disableAnimations;
    if (_auto && widget.campaigns.length > 1 && !_progress.isAnimating) {
      _progress.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (!mounted || widget.campaigns.length < 2 || !_page.hasClients) return;
    final int to = (_index + 1) % widget.campaigns.length;
    if (to == 0) {
      _page.jumpToPage(0);
    } else {
      _page.animateToPage(to,
          duration: AppMotion.slow, curve: AppMotion.dramatic);
    }
  }

  void _onPage(final int i) {
    setState(() => _index = i);
    widget.onIndexChanged(i);
    if (_auto && widget.campaigns.length > 1) _progress.forward(from: 0);
  }

  void _goTo(final int i) {
    if (!_page.hasClients) return;
    if (MediaQuery.of(context).disableAnimations) {
      _page.jumpToPage(i);
    } else {
      _page.animateToPage(i,
          duration: AppMotion.normal, curve: AppMotion.standard);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final campaigns = widget.campaigns;
    if (campaigns.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    final Widget pager = Listener(
      onPointerDown: (final _) => _progress.stop(),
      onPointerUp: (final _) {
        if (_auto && campaigns.length > 1) _progress.forward();
      },
      child: PageView.builder(
        controller: _page,
        onPageChanged: _onPage,
        itemCount: campaigns.length,
        itemBuilder: (final context, final i) => Padding(
          padding: widget.padding,
          child: AnimatedBuilder(
            animation: _page,
            builder: (final context, final child) {
              double delta = 0;
              if (_page.hasClients && _page.position.haveDimensions) {
                delta = (_page.page ?? 0) - i;
              }
              return CampaignEditorialSlide(
                campaign: campaigns[i],
                parallax: delta.clamp(-1.0, 1.0),
              );
            },
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.height != null)
          SizedBox(height: widget.height, child: pager)
        else
          Expanded(child: pager),
        if (campaigns.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: AnimatedBuilder(
              animation: _progress,
              builder: (final context, final _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < campaigns.length; i++)
                    Semantics(
                      button: true,
                      selected: i == _index,
                      label: 'Kampanya ${i + 1}',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => _goTo(i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3, vertical: AppSpacing.sm),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: AnimatedContainer(
                                duration: AppMotion.fast,
                                width: i == _index ? 28 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: cs.outlineVariant,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                alignment: Alignment.centerLeft,
                                child: i == _index
                                    ? FractionallySizedBox(
                                        widthFactor: _auto
                                            ? _progress.value.clamp(0.15, 1.0)
                                            : 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: cs.primary,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.pill),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tek slayt: afiş + gradyan + gerçek kampanya metni.
class CampaignEditorialSlide extends StatelessWidget {
  final Campaign campaign;
  final double parallax;

  const CampaignEditorialSlide({
    super.key,
    required this.campaign,
    this.parallax = 0,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final CampaignValidity validity = CampaignValidity.of(campaign);
    final double titleSize = context.responsive(
      mobile: 24,
      tablet: 26,
      desktop: 28,
    );
    final VoidCallback? open = campaignOpenAction(campaign);
    final String kicker =
        validity.expired ? 'SÜRESİ DOLDU' : 'KAMPANYA';
    final String? subtitle = validity.status ??
        (validity.until != null ? 'Son gün ${validity.until}' : null);

    return Semantics(
      button: open != null,
      label: [
        kicker.toLowerCase(),
        campaign.title,
        if (subtitle != null) subtitle,
      ].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.level3(cs.shadow),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Material(
            color: Colors.black,
            child: InkWell(
              onTap: open,
              mouseCursor:
                  open != null ? SystemMouseCursors.click : MouseCursor.defer,
              hoverColor: Colors.white.withValues(alpha: 0.08),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.translate(
                    offset: Offset(parallax * 40, 0),
                    child: Transform.scale(
                      scale: 1.15,
                      child: OptimizedCachedImage(
                        imageUrl: campaign.imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1],
                        colors: [Color(0x00000000), Color(0xD9000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 3),
                          decoration: BoxDecoration(
                            color: validity.expired
                                ? cs.error
                                : cs.primary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            kicker,
                            style: TextStyle(
                              color: validity.expired
                                  ? cs.onError
                                  : cs.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          campaign.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (open != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Kampanyayı incele',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ],
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

/// Tablet / masaüstü öne çıkan: editöryal afiş (kupon değil).
class CampaignEditorialHero extends StatelessWidget {
  final Campaign campaign;

  const CampaignEditorialHero({super.key, required this.campaign});

  @override
  Widget build(final BuildContext context) {
    final CampaignValidity validity = CampaignValidity.of(campaign);
    final VoidCallback? open = campaignOpenAction(campaign);
    final cs = context.colors;
    final double titleSize = context.responsive(
      mobile: 24,
      tablet: 26,
      desktop: 32,
    );
    final EdgeInsets copyPadding = EdgeInsets.fromLTRB(
      context.responsive(mobile: AppSpacing.lg, tablet: AppSpacing.xxl, desktop: AppSpacing.xxl),
      AppSpacing.xl,
      context.responsive(mobile: AppSpacing.lg, tablet: AppSpacing.xxl, desktop: AppSpacing.xxl),
      AppSpacing.lg,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: CampaignEditorialSlide(campaign: campaign),
        ),
        Padding(
          padding: copyPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  campaign.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    color: cs.onSurface,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ),
              if (validity.status != null ||
                  validity.until != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  validity.status ??
                      (validity.until != null
                          ? 'Son gün ${validity.until}'
                          : ''),
                  style: TextStyle(
                    color: validity.expired
                        ? cs.error
                        : cs.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (open != null)
                    FilledButton.icon(
                      onPressed: open,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm)),
                      ),
                      icon: const Icon(Icons.local_offer_outlined),
                      label: Text(validity.expired
                          ? 'Kampanyayı gör'
                          : 'Kampanyayı incele'),
                    ),
                  TextButton.icon(
                    onPressed: () => shareCampaign(campaign),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Paylaş'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
