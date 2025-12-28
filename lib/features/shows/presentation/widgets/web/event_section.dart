import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/constants/app_constants.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/features/events/presentation/providers/event_state.dart';
import 'package:ticketapp/features/login/presentation/providers/login_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_state.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import '../../../../../shared/widgets/empty_state_message_web.dart';
import '../../../../seat/presentation/pages/seat_details.dart';
import '../../../../stages/presentation/providers/stage_notifier.dart';
import '../../../domain/entities/show.dart';

class EventSection extends StatelessWidget {
  final Show showData;
  final EventState eventState;
  final StageState stageState;

  const EventSection({
    super.key,
    required this.showData,
    required this.eventState,
    required this.stageState,
  });

  @override
  Widget build(final BuildContext context) {
    if (eventState.isLoading && !eventState.hasData)
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );

    final events = eventState.dataList
            ?.where((final e) => showData.eventsId.contains(e.id))
            .toList() ??
        [];

    if (events.isEmpty)
      return EmptyStateMessage(
        message: 'Yaklaşan etkinlik bulunmamaktadır.',
        icon: Icons.calendar_today,
      );

    return Column(
      children: events.asMap().entries.map((final entry) {
        final stage = stageState.getStageById(entry.value.stageId);
        return AnimatedEventCard(
          date: entry.value.date.toString(),
          eventId: entry.value.id,
          showId: showData.id,
          stageName: stage?.name ?? "Sahne bilgisi yok",
          index: entry.key,
        );
      }).toList(),
    );
  }
}

class AnimatedEventCard extends StatelessWidget {
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
  Widget build(final BuildContext context) {
    final formatted = DateFormatter.formatForEventCard(date);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
          milliseconds: 400 + index * AppConstants.staggerAnimationDelay),
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
          onTap: () => _navigateToSeatSelection(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color(0xFFD4AF37).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFD4AF37).withOpacity(0.1),
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
                    color: Color(0xFFD4AF37).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Color(0xFFD4AF37).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
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

  void _navigateToSeatSelection(final BuildContext context) {
    final ref = ProviderScope.containerOf(context);
    final String? userId = ref.read(loginProvider).user?.uid ??
        ref.read(userProvider).dataSingle?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")));
      return;
    }
    // 4. Navigasyon (Artık userId kesinlikle bir String)
    if (context.mounted)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (final _) => SeatSelectionScreen(
            showId: showId,
            eventId: eventId,
            customerId: userId,
          ),
        ),
      );
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
