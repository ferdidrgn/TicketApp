import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/util/date_formatter.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/bento/bento_primitives.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../favorite/presentation/providers/favorite_provider.dart';
import '../../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../../tickets/presentation/providers/my_ticket_provider.dart';

/// Home sayfasının ALTINA eklenen ek dashboard bileşenleri. Giriş
/// yapılmamışsa veya gösterilecek veri yoksa sessizce hiçbir şey
/// render etmezler (boş kart göstermek yerine).

class UpcomingTicketDashboardCard extends ConsumerWidget {
  const UpcomingTicketDashboardCard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final ticketsAsync = ref.watch(myTicketsProvider(userId));
    final upcoming = ticketsAsync.value?.upcoming ?? const [];
    if (upcoming.isEmpty) return const SizedBox.shrink();

    upcoming.sort((final a, final b) {
      final da = DateFormatter.parseDateString(a.event?.date) ?? DateTime(9999);
      final db = DateFormatter.parseDateString(b.event?.date) ?? DateTime(9999);
      return da.compareTo(db);
    });
    final next = upcoming.first;
    final eventDate = DateFormatter.parseDateString(next.event?.date);
    final daysLeft = eventDate != null
        ? eventDate.difference(DateTime.now()).inDays
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BentoSectionHeader(
          title: 'Yaklaşan Biletin',
          subtitle: 'Geri sayım başladı',
          icon: LucideIcons.calendarDays,
        ),
        const SizedBox(height: 12),
        BentoCard(
          radius: 22,
          gradient: const LinearGradient(
            colors: [BentoColors.indigo, BentoColors.indigoDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: Colors.transparent,
          onTap: () {
            HapticFeedback.lightImpact();
            NavigationHandler.goToMyTickets(context, userId);
          },
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  daysLeft == null
                      ? '🎭'
                      : daysLeft <= 0
                          ? 'BUGÜN'
                          : '$daysLeft',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next.show?.name ?? 'Gösterin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysLeft == null
                          ? 'Bilet detayını görüntüle'
                          : daysLeft <= 0
                              ? 'Bugün sahnede!'
                              : '$daysLeft gün kaldı${next.stage != null ? ' • ${next.stage!.name}' : ''}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }
}

class FavoritesDashboardRow extends ConsumerWidget {
  const FavoritesDashboardRow({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final favoritesAsync = ref.watch(myFavoritesProvider);
    final shows = favoritesAsync.value?.shows ?? const [];
    if (shows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BentoSectionHeader(
          title: 'Favorilerin',
          subtitle: 'Kalbinde yer edenler',
          icon: LucideIcons.heart,
          onActionTap: () => NavigationHandler.goToFavorites(context),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shows.length,
            separatorBuilder: (final _, final __) => const SizedBox(width: 12),
            itemBuilder: (final context, final index) {
              final show = shows[index];
              return ShowCard(
                imageUrl: show.imageUrl,
                gameName: show.name,
                width: 130,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (final _) =>
                              ShowDetailPage(showId: show.id)));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
