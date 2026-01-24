import 'package:flutter/material.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/util/date_formatter.dart';
import 'package:ticketapp/features/events/domain/entities/event.dart';
import '../../../../stages/domain/entities/stage.dart';

class ShowEventList extends StatelessWidget {
  final List<Event> events;
  final List<Stage> stages;
  final Function(String eventId) onTicketTap;

  const ShowEventList({
    super.key,
    required this.events,
    required this.stages,
    required this.onTicketTap,
  });

  @override
  Widget build(final BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDarkMode;

    // RENKLER
    const brandRed = AppLightColors.primary;
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppLightColors.textPrimary;

    // Kart Arka Planı: Dark modda senin tanımladığın Surface rengi
    final cardBgColor = isDark ? AppDarkColors.surface : AppLightColors.surface;

    // Tarih Kutusu Arka Planı: Dark modda biraz daha koyu gri
    final dateBoxColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Row(
            children: [
              Container(width: 4, height: 24, color: brandRed),
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
              final stage = stages.firstWhere(
                (final s) => s.id == event.stageId,
                orElse: () => const Stage(
                    id: '0',
                    name: 'Sahne Bilgisi Yok',
                    imageUrl: '',
                    capacity: '',
                    description: '',
                    communication: '',
                    address: '',
                    locationLat: 0.0,
                    locationLng: 0.0,
                    createdAt: '',
                    updatedAt: '',
                    showsId: []),
              );
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
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? Border.all(color: Colors.white10) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: dateBoxColor,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: brandRed.withOpacity(0.5)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dateInfo['day'] ?? '00',
                                style: const TextStyle(
                                  color: brandRed,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stage.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${dateInfo['time']} • İstanbul",
                                style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 13),
                              ),
                              const Spacer(),
                              // Bilet Al Butonu
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: brandRed.withOpacity(0.15),
                                  // ✅ Hafif Kırmızı Zemin
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "BİLET AL >",
                                  style: TextStyle(
                                    color: brandRed,
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
