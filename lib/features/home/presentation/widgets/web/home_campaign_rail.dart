import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';

/// "Öne Çıkan Kampanyalar" — gerçek bir SLAYT/karusel.
///
/// 🔥 DÜZELTME: Önceden yan yana kaydırılan, hepsi aynı kalıpta küçük
/// (340x260) kartlardan oluşan sade bir `ListView` idi — kullanıcı bunu
/// "daha farklı tasarımlar, daha görsel, kullanıcı deneyimine odaklı"
/// olarak yeniden istedi. Artık tek seferde TEK, büyük, sinematik bir
/// kampanya kartı gösteren gerçek bir `PageView` slaytı: nokta göstergeler,
/// masaüstünde hover'da beliren ok butonları, birden fazla kampanya varsa
/// otomatik ilerleme (hover'da duraklıyor) — tıpkı bir "hero slider" gibi.
/// Kartın kendisi de artık çift katmanlı: büyük görsel + üzerine oturan,
/// numaralandırılmış ("01/03" gibi) editoryal bir bilgi paneli.
class HomeCampaignRail extends StatefulWidget {
  final List<Campaign> campaigns;
  final void Function(int index) onCampaignTap;

  const HomeCampaignRail({
    super.key,
    required this.campaigns,
    required this.onCampaignTap,
  });

  @override
  State<HomeCampaignRail> createState() => _HomeCampaignRailState();
}

class _HomeCampaignRailState extends State<HomeCampaignRail> {
  late final PageController _controller = PageController(viewportFraction: 1);
  Timer? _autoAdvanceTimer;
  int _activeIndex = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _scheduleAutoAdvance();
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (widget.campaigns.length <= 1) return;
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 6), (final _) {
      if (!mounted || _paused || !_controller.hasClients) return;
      final next = (_activeIndex + 1) % widget.campaigns.length;
      _controller.animateToPage(next,
          duration: AppMotion.slow, curve: AppMotion.standard);
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goTo(final int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(index,
        duration: AppMotion.slow, curve: AppMotion.standard);
  }

  @override
  Widget build(final BuildContext context) {
    final campaigns = widget.campaigns;
    if (campaigns.isEmpty) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (final _) => setState(() => _paused = true),
      onExit: (final _) => setState(() => _paused = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 400,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: campaigns.length,
                  onPageChanged: (final i) =>
                      setState(() => _activeIndex = i),
                  itemBuilder: (final context, final index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _CampaignSlide(
                      campaign: campaigns[index],
                      index: index,
                      total: campaigns.length,
                      onTap: () => widget.onCampaignTap(index),
                    ),
                  ),
                ),
                if (campaigns.length > 1) ...[
                  _SlideArrow(
                    alignment: Alignment.centerLeft,
                    icon: Icons.chevron_left_rounded,
                    onTap: () =>
                        _goTo((_activeIndex - 1 + campaigns.length) %
                            campaigns.length),
                  ),
                  _SlideArrow(
                    alignment: Alignment.centerRight,
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _goTo((_activeIndex + 1) % campaigns.length),
                  ),
                ],
              ],
            ),
          ),
          if (campaigns.length > 1) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < campaigns.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: AppMotion.normal,
                        curve: AppMotion.standard,
                        width: i == _activeIndex ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _activeIndex
                              ? WebColors.primaryGold
                              : WebColors.primaryGold.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SlideArrow extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  const _SlideArrow(
      {required this.alignment, required this.icon, required this.onTap});

  @override
  Widget build(final BuildContext context) => Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Semantics(
            button: true,
            label: alignment == Alignment.centerLeft
                ? 'Önceki kampanya'
                : 'Sonraki kampanya',
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WebColors.veryDarkBlue.withOpacity(0.55),
                  border: Border.all(
                      color: WebColors.primaryGold.withOpacity(0.4)),
                ),
                child:
                    Icon(icon, color: WebColors.primaryGoldLight, size: 26),
              ),
            ),
          ),
        ),
      );
}

class _CampaignSlide extends StatefulWidget {
  final Campaign campaign;
  final int index;
  final int total;
  final VoidCallback onTap;

  const _CampaignSlide({
    required this.campaign,
    required this.index,
    required this.total,
    required this.onTap,
  });

  @override
  State<_CampaignSlide> createState() => _CampaignSlideState();
}

class _CampaignSlideState extends State<_CampaignSlide> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            decoration: BoxDecoration(
              borderRadius: AppRadius.asymLg,
              boxShadow: [
                BoxShadow(
                  color: WebColors.primaryGold
                      .withOpacity(_hovered ? 0.28 : 0.16),
                  blurRadius: _hovered ? 40 : 24,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.asymLg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedScale(
                    duration: AppMotion.slow,
                    curve: AppMotion.standard,
                    scale: _hovered ? 1.04 : 1.0,
                    child: OptimizedCachedImage(
                      imageUrl: widget.campaign.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          WebColors.veryDarkBlue.withOpacity(0.15),
                          WebColors.veryDarkBlue.withOpacity(0.55),
                          WebColors.veryDarkBlue.withOpacity(0.92),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // Sağ üstte "01 / 03" gibi editoryal bir slayt sayacı —
                  // slaytın gerçekten bir dizinin parçası olduğunu hissettirir.
                  Positioned(
                    top: 24,
                    right: 28,
                    child: Text(
                      '${(widget.index + 1).toString().padLeft(2, '0')} / '
                      '${widget.total.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: WebColors.goldGradient,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(2),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'KAMPANYA',
                            style: TextStyle(
                              color: WebColors.veryDarkBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.campaign.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: WebColors.whiteText,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedOpacity(
                          duration: AppMotion.normal,
                          opacity: _hovered ? 1 : 0.8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Kampanyayı Gör',
                                style: TextStyle(
                                  color: WebColors.primaryGoldLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  color: WebColors.primaryGoldLight, size: 16),
                            ],
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
      );
}
