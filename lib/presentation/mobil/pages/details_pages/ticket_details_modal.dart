import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/util/date_formatter.dart';
import '../my_ticket/my_ticket_viewmodel.dart';

class TicketDetailsModal extends StatelessWidget {
  final DetailedTicket ticket;

  const TicketDetailsModal({required this.ticket});

  @override
  Widget build(final BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (final context, final scrollController) =>
            _LuxuryTicketDetails(controller: scrollController, ticket: ticket));
  }
}

class _LuxuryTicketDetails extends StatelessWidget {
  final ScrollController controller;
  final DetailedTicket ticket;

  const _LuxuryTicketDetails({required this.controller, required this.ticket});

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final dateInfo = DateFormatter.formatForEventCard(ticket.event?.date ?? '');
    final eventYear = DateFormatter
        .parseDateString(ticket.event?.date)
        ?.year ??
        DateTime
            .now()
            .year;
    final dateText = "${dateInfo['day']} ${dateInfo['monthName']} $eventYear";
    final timeText = dateInfo['time'] ?? '--:--';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, -10))
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3))),

          Expanded(
            child: ListView(
              controller: controller,
              padding: EdgeInsets.zero,
              children: [
                // Event Image - FULL WIDTH
                _LargeEventImage(
                    imageUrl: ticket.show?.imageUrl ?? '',
                    title: ticket.show?.name ?? 'Gösteri Adı',
                    theme: theme),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // QR Code Section
                      _LargeQRCodeSection(
                          ticketId: ticket.ticket.id, theme: theme),
                      const SizedBox(height: 32),

                      // Ticket Details
                      _DetailsSection(
                          ticket: ticket,
                          dateText: dateText,
                          timeText: timeText,
                          theme: theme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeEventImage extends StatelessWidget {
  final String imageUrl;
  final String title;
  final ThemeData theme;

  const _LargeEventImage(
      {required this.imageUrl, required this.title, required this.theme});

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: 240,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 2),
          BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -5)
        ],
      ),
      child: Stack(
        children: [
          // Image - FULL WIDTH
          CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (final context, final url) =>
                Container(
                    height: 240,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surfaceVariant,
                            theme.colorScheme.surfaceContainer,
                          ],
                        ))),
            errorWidget: (final context, final url, final error) =>
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        theme.colorScheme.surfaceVariant,
                        theme.colorScheme.surfaceContainer
                      ])),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_rounded,
                          size: 64, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Görsel yüklenemedi',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // BAŞLIK - ALT SOL KÖŞE
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Text(title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  shadows: [
                    Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(2, 2)),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Modal içindeki QR kod bölümü.
class _LargeQRCodeSection extends StatelessWidget {
  final String ticketId;
  final ThemeData theme;

  const _LargeQRCodeSection({
    required this.ticketId,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Text('Bilet QR Kodu',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 22)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.8),
                theme.colorScheme.primaryContainer.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                  spreadRadius: -5),
              BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // QR Kod
                  Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: theme.colorScheme.shadow.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: QrImageView(
                        data: ticketId,
                        version: QrVersions.auto,
                        size: 100,
                        eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: theme.colorScheme.primary),
                        dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: theme.colorScheme.primary),
                      )),
                  const SizedBox(width: 20),

                  // QR Kod bilgisi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color:
                                theme.colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('GİRİŞ KODU',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2))),
                        const SizedBox(height: 12),
                        Text(
                          'Bu kodu girişte\ngösterin',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                              height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.2))),
                            child: Text(ticketId,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Modal içindeki bilet detaylarını (koltuk, sahne, tarih vb.)
/// tek bir çerçeve içinde dikey bir liste olarak gösterir.
class _DetailsSection extends StatelessWidget {
  final DetailedTicket ticket;
  final String dateText;
  final String timeText;
  final ThemeData theme;

  const _DetailsSection({
    required this.ticket,
    required this.dateText,
    required this.timeText,
    required this.theme,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Row(
          children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Text('Bilet Bilgileri',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 22))
          ],
        ),
        const SizedBox(height: 20),

        // QR Kod stiline sahip yeni liste çerçevesi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceContainer.withOpacity(0.8),
                theme.colorScheme.surfaceContainer.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.primary, width: 1),
            boxShadow: [
              BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            children: [
              _InfoListTile(
                  icon: Icons.event_seat_rounded,
                  title: 'Koltuk Numaraları',
                  subtitle: ticket.ticket.buySeats.join(", "),
                  theme: theme,
                  isHighlighted: true),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.location_on_rounded,
                  title: 'Sahne',
                  subtitle: ticket.stage?.name ?? 'Yükleniyor...',
                  theme: theme),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'Tarih',
                  subtitle: dateText,
                  theme: theme),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.access_time_filled_rounded,
                  title: 'Saat',
                  subtitle: timeText,
                  theme: theme),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.payments_rounded,
                  title: 'Ödenen Tutar',
                  subtitle: '${ticket.ticket.orderPrice} TL',
                  theme: theme,
                  isHighlighted: true),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.credit_card_rounded,
                  title: 'Ödeme Yöntemi',
                  subtitle: ticket.ticket.orderMethod,
                  theme: theme,
                  isLast: true)
            ],
          ),
        ),
      ],
    );
  }
}

/// Çerçeve içindeki listede kullanılacak ayırıcı (divider) widget'ı.
class _CustomDivider extends StatelessWidget {
  const _CustomDivider();

  @override
  Widget build(final BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(
            height: 1,
            color: Theme
                .of(context)
                .colorScheme
                .outline
                .withOpacity(0.2)));
  }
}

/// Dikey liste içindeki her bir yatay bilgi satırı.
class _InfoListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final bool isHighlighted;
  final bool isLast;

  const _InfoListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    this.isHighlighted = false,
    this.isLast = false,
  });

  @override
  Widget build(final BuildContext context) {
    // İkonun "arka plan" rengini belirler
    final iconBackgroundColor =
    isHighlighted ? theme.colorScheme.primary : theme.colorScheme.tertiary;

    // Alt başlığın (değerin) rengini belirler
    final subtitleColor =
    isHighlighted ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // İkon
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: iconBackgroundColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24)),
        const SizedBox(width: 16),

        // Başlık ve Alt Başlık
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: subtitleColor,
                      height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
