import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';

/// "Öne Çıkan Kampanyalar" yatay vitrin şeridi.
///
/// Editoryal bir dergi sayfası gibi davranır: her kart geniş bir görsel,
/// üzerinde kampanya başlığı ve asimetrik köşeli bir "Kampanyayı Gör" etiketi
/// taşır. Sadece web ana sayfasına özeldir.
class HomeCampaignRail extends StatelessWidget {
  final List<Campaign> campaigns;
  final void Function(int index) onCampaignTap;

  const HomeCampaignRail({
    super.key,
    required this.campaigns,
    required this.onCampaignTap,
  });

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 260,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: campaigns.length,
          separatorBuilder: (final _, final __) => const SizedBox(width: 16),
          itemBuilder: (final context, final index) => _CampaignCard(
            campaign: campaigns[index],
            onTap: () => onCampaignTap(index),
          ),
        ),
      );
}

class _CampaignCard extends StatefulWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const _CampaignCard({required this.campaign, required this.onTap});

  @override
  State<_CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends State<_CampaignCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 340,
            transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(32),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(32),
              ),
              border: Border.all(
                color: _hovered
                    ? WebColors.primaryGold.withOpacity(0.6)
                    : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_hovered
                          ? WebColors.primaryGold
                          : WebColors.veryDarkBlue)
                      .withOpacity(_hovered ? 0.32 : 0.35),
                  blurRadius: _hovered ? 26 : 16,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(32),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(32),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OptimizedCachedImage(
                    imageUrl: widget.campaign.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          WebColors.veryDarkBlue.withOpacity(0.55),
                          WebColors.veryDarkBlue.withOpacity(0.92),
                        ],
                        stops: const [0.35, 0.7, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: WebColors.goldGradient,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(2),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'KAMPANYA',
                            style: TextStyle(
                              color: WebColors.veryDarkBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.campaign.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: WebColors.whiteText,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: _hovered ? 1 : 0.7,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Kampanyayı Gör',
                                style: TextStyle(
                                  color: WebColors.primaryGoldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded,
                                  color: WebColors.primaryGoldLight, size: 14),
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
