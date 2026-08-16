import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/footers/footer.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../../tickets/presentation/providers/my_ticket_provider.dart';
import 'theater_section_divider.dart';

/// 🎭 RADİKAL WEB ANA SAYFA GÖVDESİ
///
/// `home_page_mobile.dart` içindeki `HomePage`, mobil VE web'de aynı dar,
/// tek sütunlu mobil bileşen ağacını kullanıyordu — web'de mobil tasarımın
/// kenardan kenara gerilmesi. Bu widget, geniş ekranlar için TAMAMEN AYRI,
/// masaüstüne özel bir düzen kurar: tam genişlik hero banner, kategori
/// filtre şeridi, çok sütunlu (ana içerik + kenar çubuğu) grid ve gerçek bir
/// web footer'ı. Mobil tarafta HİÇBİR ŞEY değişmedi — bu widget sadece
/// `isLargeScreen == true` olduğunda devreye giriyor.
class AppHomeWebBody extends StatelessWidget {
  final List<Campaign> campaigns;
  final List<Show> shows;
  final List<Stage> stages;
  final VoidCallback onOpenSearch;

  const AppHomeWebBody({
    super.key,
    required this.campaigns,
    required this.shows,
    required this.stages,
    required this.onOpenSearch,
  });

  @override
  Widget build(final BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 1400 ? 100.0 : (width > 1000 ? 60.0 : 32.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroBanner(
            campaigns: campaigns, shows: shows, onOpenSearch: onOpenSearch),
        const TheaterSectionDivider(style: DividerStyle.iconCenter, height: 90),
        if (shows.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _CategoryChipBar(shows: shows),
          ),
          const SizedBox(height: 40),
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: LayoutBuilder(builder: (final context, final constraints) {
            final bool showSidebar = constraints.maxWidth > 980;
            final mainColumn = _MainColumn(shows: shows, stages: stages);
            if (!showSidebar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  mainColumn,
                  const SizedBox(height: 48),
                  _Sidebar(campaigns: campaigns),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: mainColumn),
                const SizedBox(width: 40),
                Expanded(flex: 3, child: _Sidebar(campaigns: campaigns)),
              ],
            );
          }),
        ),
        const SizedBox(height: 80),
        const Footer(),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HERO BANNER
// ══════════════════════════════════════════════════════════════
class _HeroBanner extends StatelessWidget {
  final List<Campaign> campaigns;
  final List<Show> shows;
  final VoidCallback onOpenSearch;

  const _HeroBanner(
      {required this.campaigns,
      required this.shows,
      required this.onOpenSearch});

  @override
  Widget build(final BuildContext context) {
    final Campaign? campaign = campaigns.isNotEmpty ? campaigns.first : null;
    final Show? show = shows.isNotEmpty ? shows.first : null;
    final String imageUrl = campaign?.imageUrl ?? show?.imageUrl ?? '';
    final String title = campaign?.title ?? show?.name ?? 'TiyatRol Sahnesi';

    return SizedBox(
      height: 460,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
          else
            Container(color: WebColors.darkBlueBackground),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WebColors.darkBlueBackground.withOpacity(0.4),
                  WebColors.darkBlueBackground.withOpacity(0.75),
                  WebColors.darkBlueBackground,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 60,
            right: 60,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(height: 2, width: 40, color: WebColors.primaryGold),
                    const SizedBox(width: 16),
                    const Text('SAHNEDE ŞİMDİ',
                        style: TextStyle(
                            color: WebColors.primaryGold,
                            fontSize: 13,
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (campaign != null && campaign.url.isNotEmpty) {
                          launchUrl(Uri.parse(campaign.url));
                        } else if (show != null) {
                          NavigationHandler.goToShow(
                              context, show.id, show.name);
                        } else {
                          NavigationHandler.goToDiscover(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WebColors.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('KEŞFETMEYE BAŞLA',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: onOpenSearch,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('OYUN / SAHNE ARA',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KATEGORİ FİLTRE ŞERİDİ
// ══════════════════════════════════════════════════════════════
class _CategoryChipBar extends StatelessWidget {
  final List<Show> shows;
  const _CategoryChipBar({required this.shows});

  @override
  Widget build(final BuildContext context) {
    final categories = shows
        .map((final s) => s.category)
        .where((final c) => c.trim().isNotEmpty)
        .toSet()
        .toList();
    if (categories.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories
          .map((final c) => InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () =>
                    NavigationHandler.goToDiscoverWithCategory(context, c),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: WebColors.primaryGold.withOpacity(0.4)),
                  ),
                  child: Text(c.toUpperCase(),
                      style: const TextStyle(
                          color: WebColors.primaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                ),
              ))
          .toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ANA SÜTUN: OYUNLAR + MEKANLAR GRID'İ
// ══════════════════════════════════════════════════════════════
class _MainColumn extends StatelessWidget {
  final List<Show> shows;
  final List<Stage> stages;

  const _MainColumn({required this.shows, required this.stages});

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WebSectionTitle(title: 'Öne Çıkan Oyunlar', icon: Icons.theater_comedy_rounded),
        const SizedBox(height: 24),
        if (shows.isEmpty)
          const _EmptySection(text: 'Henüz gösteri eklenmemiş.')
        else
          LayoutBuilder(builder: (final context, final constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.72,
              ),
              itemCount: shows.length,
              itemBuilder: (final context, final index) =>
                  _WebShowTile(show: shows[index]),
            );
          }),
        const SizedBox(height: 56),
        const _WebSectionTitle(title: 'Mekanlar', icon: Icons.stadium_rounded),
        const SizedBox(height: 24),
        if (stages.isEmpty)
          const _EmptySection(text: 'Henüz sahne eklenmemiş.')
        else
          LayoutBuilder(builder: (final context, final constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 1.4,
              ),
              itemCount: stages.length,
              itemBuilder: (final context, final index) =>
                  _WebStageTile(stage: stages[index]),
            );
          }),
      ],
    );
  }
}

class _WebShowTile extends StatelessWidget {
  final Show show;
  const _WebShowTile({required this.show});

  @override
  Widget build(final BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => NavigationHandler.goToShow(context, show.id, show.name),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(show.category.toUpperCase(),
                          style: const TextStyle(
                              color: WebColors.primaryGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _WebStageTile extends StatelessWidget {
  final Stage stage;
  const _WebStageTile({required this.stage});

  @override
  Widget build(final BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => NavigationHandler.goToStage(context, stage.id, stage.name),
        child: Container(
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                child: SizedBox(
                  width: 100,
                  height: double.infinity,
                  child: CachedNetworkImage(
                      imageUrl: stage.imageUrl, fit: BoxFit.cover),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(stage.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(stage.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// KENAR ÇUBUĞU: KAMPANYALAR + HIZLI BAĞLANTILAR
// ══════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  final List<Campaign> campaigns;
  const _Sidebar({required this.campaigns});

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QuickLinksCard(),
        if (campaigns.length > 1) ...[
          const SizedBox(height: 32),
          const _WebSectionTitle(title: 'Kampanyalar', icon: Icons.local_offer_rounded),
          const SizedBox(height: 16),
          ...campaigns.skip(1).take(4).map((final c) => _CampaignTile(campaign: c)),
        ],
      ],
    );
  }
}

class _CampaignTile extends StatelessWidget {
  final Campaign campaign;
  const _CampaignTile({required this.campaign});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => NavigationHandler.goToCampaigns(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WebColors.darkBlueSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: CachedNetworkImage(
                        imageUrl: campaign.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
}

class _QuickLinksCard extends ConsumerWidget {
  const _QuickLinksCard();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HIZLI ERİŞİM',
              style: TextStyle(
                  color: WebColors.primaryGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          const SizedBox(height: 16),
          _QuickLinkRow(
            icon: Icons.favorite_rounded,
            label: 'Favorilerim',
            onTap: () => NavigationHandler.goToFavorites(context),
          ),
          _QuickLinkRow(
            icon: Icons.confirmation_number_rounded,
            label: 'Biletlerim',
            onTap: () {
              if (userId != null) {
                NavigationHandler.goToMyTickets(context, userId);
              } else {
                NavigationHandler.goToLogin(context);
              }
            },
          ),
          _QuickLinkRow(
            icon: Icons.notifications_rounded,
            label: 'Bildirimler',
            badgeCount: unread,
            onTap: () => NavigationHandler.goToNotifications(context),
          ),
          if (userId != null) const _SidebarUpcomingTicket(),
        ],
      ),
    );
  }
}

class _QuickLinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  const _QuickLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(final BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: WebColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white24, size: 18),
            ],
          ),
        ),
      );
}

class _SidebarUpcomingTicket extends ConsumerWidget {
  const _SidebarUpcomingTicket();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final upcoming =
        ref.watch(myTicketsProvider(userId)).value?.upcoming ?? const [];
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final next = upcoming.first;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WebColors.primaryGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_rounded,
                color: WebColors.primaryGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Yaklaşan bilet: ${next.show?.name ?? 'Gösteri'}',
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ORTAK KÜÇÜK BİLEŞENLER
// ══════════════════════════════════════════════════════════════
class _WebSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _WebSectionTitle({required this.title, required this.icon});

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Icon(icon, color: WebColors.primaryGold, size: 24),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
        ],
      );
}

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.5))),
      );
}
