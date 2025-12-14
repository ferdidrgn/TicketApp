import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/features/events/domain/entities/event.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_state.dart';

import '../../../../stages/presentation/providers/stage_notifier.dart';

class ShowEventList extends StatelessWidget {
  final List<Event> events;
  final StageState stageState;
  final Function(String eventId) onTicketTap;

  const ShowEventList({
    super.key,
    required this.events,
    required this.stageState,
    required this.onTicketTap,
  });

  @override
  Widget build(final BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final surfaceColor = theme.cardColor; // Kart rengi (Dark/Light uyumlu)
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Row(
            children: [
              Container(width: 4, height: 24, color: primaryColor),
              const SizedBox(width: 10),
              Text(
                "ETKİNLİK TAKVİMİ",
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: events.length,
            itemBuilder: (final context, final index) {
              final event = events[index];
              final stage = stageState.getStageById(event.stageId);
              final dateInfo =
                  DateFormatter.formatForEventCard(event.date.toString());

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 15),
                child: InkWell(
                  onTap: () => onTicketTap(event.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        // Tarih Kutusu
                        Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.5)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dateInfo['day'] ?? '00',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dateInfo['monthName']?.toUpperCase() ?? 'AAA',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Bilgiler
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stage?.name ?? 'Sahne Bilgisi Yok',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${dateInfo['time']} • İstanbul",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "BİLET AL >",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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
            },
          ),
        ),
      ],
    );
  }
}
