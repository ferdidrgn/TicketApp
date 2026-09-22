import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../campaigns/domain/entities/campaign.dart';

/// Web karşılığı: mobildeki `TicketStubCard` ("GÜNÜN FIRSATI" kartı).
///
/// Artık `campaignsProvider`'dan gelen gerçek ilk kampanyayı gösterir
/// (bkz. `home_page_web.dart`'ın `campaigns` değişkeni) — daha önce burada
/// sabit "Romeo & Juliet %20 İndirim" metni ve tıklanamayan bir stok görsel
/// vardı. Hiç kampanya yoksa banner tamamen gizlenir.
class HomePromoBanner extends StatelessWidget {
  final Campaign? campaign;
  final int campaignIndex;

  const HomePromoBanner({super.key, this.campaign, this.campaignIndex = 0});

  // Önceden bottomLeft/bottomRight'ı ters (6/32/32/6, çapraz bir kesim)
  // olan tek örnekti — uygulamanın her yerdeki asimetrik köşe imzasıyla
  // (bir kenar keskin, karşı kenar belirgin yuvarlak) aynı yöne çevrildi.
  static const _radius = AppRadius.asymLg;

  @override
  Widget build(final BuildContext context) {
    final campaign = this.campaign;
    if (campaign == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => NavigationHandler.goToCampaigns(context,
          index: campaignIndex),
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          borderRadius: _radius,
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                campaign.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (final context, final error, final stack) =>
                    const ColoredBox(color: WebColors.darkBlueSurface),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      WebColors.veryDarkBlue.withOpacity(0.92),
                      WebColors.veryDarkBlue.withOpacity(0.55),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'GÜNÜN FIRSATI',
                      style: TextStyle(
                        color: WebColors.primaryGoldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      campaign.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WebColors.whiteText,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kampanyayı Keşfet',
                      style: TextStyle(
                        color: WebColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
