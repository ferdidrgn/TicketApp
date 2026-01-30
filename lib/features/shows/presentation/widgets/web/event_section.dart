import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../events/domain/entities/event.dart';
import '../../../../seat/presentation/pages/seat_details.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../domain/entities/show.dart';

class EventSection extends StatelessWidget {
  final Show showData;
  final List<Event> events;
  final List<Stage> stages;

  const EventSection({
    super.key,
    required this.showData,
    required this.events,
    required this.stages,
  });

  @override
  Widget build(final BuildContext context) {
    // Veri zaten showDetailProvider'dan hazır geldiği için isLoading kontrolüne gerek yok
    if (events.isEmpty)
      return const Center(
        child: Text('Yaklaşan etkinlik bulunmamaktadır.',
            style: TextStyle(color: Colors.white38)),
      );

    return Column(
      children: events.asMap().entries.map((final entry) {
        final stage = stages.firstWhere(
            (final s) => s.id == entry.value.stageId,
            orElse: () => const Stage(
                id: '0',
                name: 'Sahne bilgisi yok',
                imageUrl: '',
                capacity: '',
                description: '',
                communication: '',
                address: '',
                locationLat: 0.0,
                locationLng: 0.0,
                createdAt: '',
                updatedAt: '',
                showsId: []));

        return AnimatedEventCard(
          date: entry.value.date.toString(),
          eventId: entry.value.id,
          showId: showData.id,
          stageName: stage.name,
          index: entry.key,
        );
      }).toList(),
    );
  }
}

class AnimatedEventCard extends ConsumerWidget {
  final String date;
  final String eventId;
  final String showId;
  final String stageName;
  final int index;

  const AnimatedEventCard({
    super.key,
    required this.date,
    required this.eventId,
    required this.showId,
    required this.stageName,
    required this.index,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formatted = DateFormatter.formatForEventCard(date);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 70),
      builder: (final context, final value, final child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          // 🔥 ref'i fonksiyona paslıyoruz
          onTap: () => _navigateToSeatSelection(context, ref),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e), //
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.3), //
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.1), //
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              children: [
                DateBox(
                  day: formatted['day'] ?? '?',
                  month: formatted['monthName'] ?? '-',
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stageName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      EventLocationRow(time: formatted['time'] ?? '--:--'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSeatSelection(
      final BuildContext context, final WidgetRef ref) {
    // Auth sağlayıcını watch veya read ederek kullanıcıyı al
    final String? userId = ref.read(currentUserProvider).value?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Bilet almak için giriş yapmalısınız.")));
      return;
    }

    if (context.mounted)
      NavigationHandler.goToSeatSelection(context, showId, eventId, userId);
  }
}

class DateBox extends StatelessWidget {
  final String day;
  final String month;

  const DateBox({
    super.key,
    required this.day,
    required this.month,
  });

  @override
  Widget build(final BuildContext context) => Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD4AF37),
              Color(0xFFF5E6A3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0a0a1a),
              ),
            ),
            Text(
              month,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0a0a1a),
              ),
            ),
          ],
        ),
      );
}

class EventLocationRow extends StatelessWidget {
  final String time;

  const EventLocationRow({super.key, required this.time});

  @override
  Widget build(final BuildContext context) => Row(
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Color(0xFFD4AF37),
          ),
          const SizedBox(width: 4),
          Text(
            "İstanbul",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.access_time,
            size: 16,
            color: Color(0xFFD4AF37),
          ),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      );
}
