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
    if (events.isEmpty)
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("Yaklaşan etkinlik bulunmamaktadır.",
            style: TextStyle(color: Colors.white38)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bölüm Başlığı
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Row(
            children: [
              Container(width: 4, height: 24, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 10),
              const Text(
                "ETKİNLİK TAKVİMİ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        // Liste
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
                      color: const Color(0xFF151525),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5))
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        // Tarih Kutusu
                        Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0a0a1a),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    const Color(0xFFD4AF37).withOpacity(0.3)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(dateInfo['day'] ?? '00',
                                  style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  dateInfo['monthName']?.toUpperCase() ?? 'AAA',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
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
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Colors.white54, size: 14),
                                  const SizedBox(width: 5),
                                  Text(dateInfo['time'] ?? '00:00',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 13)),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFD4AF37).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "BİLET AL >",
                                  style: TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
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
