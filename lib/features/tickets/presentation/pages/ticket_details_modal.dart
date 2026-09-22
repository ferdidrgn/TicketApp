import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/magic_box.dart';
import '../providers/my_ticket_provider.dart';

class TicketDetailsModal extends StatelessWidget {
  final DetailedTicket ticket;

  const TicketDetailsModal({super.key, required this.ticket});

  @override
  Widget build(final BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (final _, final scrollController) =>
            _LuxuryTicketDetails(controller: scrollController, ticket: ticket));
  }
}

class _LuxuryTicketDetails extends StatelessWidget {
  final ScrollController controller;
  final DetailedTicket ticket;

  const _LuxuryTicketDetails({required this.controller, required this.ticket});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    final dateInfo = DateFormatter.formatForEventCard(ticket.event?.date ?? '');
    final dateText =
        "${dateInfo['day']} ${dateInfo['monthName']} ${DateTime.now().year}";

    return Container(
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Stack(
        children: [
          ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Semantics(
                  label: 'Bileti kapatmak için aşağı sürükleyin',
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: themeColors.outlineVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              _LargeEventImage(
                  imageUrl: ticket.show?.imageUrl ?? '',
                  title: ticket.show?.name ?? 'Gösteri'),
              const SizedBox(height: AppSpacing.xxxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  children: [
                    _LargeQRCodeSection(ticketId: ticket.ticket.id),
                    const SizedBox(height: AppSpacing.xxxl),
                    _DetailsSection(
                        ticket: ticket,
                        dateText: dateText,
                        timeText: dateInfo['time'] ?? '--:--'),
                    if (ticket.show != null || ticket.stage != null) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _NavigationActionsSection(ticket: ticket),
                    ],
                    const SizedBox(height: AppSpacing.huge),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LargeQRCodeSection extends StatelessWidget {
  final String ticketId;

  const _LargeQRCodeSection({required this.ticketId});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;

    // 1. ÜST KATMAN (Sadece saf buzlu cam, üzerinde yazı yok!)
    final Widget foreground = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 140,
          height: 140,
          color: themeColors.primary.withOpacity(0.15),
        ),
      ),
    );

    // 2. ALT KATMAN (Net QR Kod)
    // Not: QR kodun arka planı burada kasıtlı olarak sabit beyaz kalıyor —
    // QR tarayıcıların güvenilir okuması için yüksek kontrast (siyah
    // modül / beyaz zemin) şart, temaya göre değişemez.
    final Widget background = Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: QrImageView(
        data: ticketId,
        version: QrVersions.auto,
        size: 116,
        eyeStyle:
            QrEyeStyle(eyeShape: QrEyeShape.square, color: themeColors.primary),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: themeColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // SİHİRLİ QR ALANI
          Semantics(
            label: 'Bilet QR kodu, giriş için görevliye gösterin',
            image: true,
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MagicBox(
                      radius: 0.28,
                      foreground: foreground,
                      background: background),
                  // YAZI VE İKONU BURAYA, MASKEDEN BAĞIMSIZ KOYUYORUZ
                  // Dokunma başladığında bunu gizlemek istersen bir ValueNotifier kullanabilirsin
                  // ama şu an orta kısım silineceği için bu ikonlar zaten kenara itilmiş olacak.
                  IgnorePointer(
                    // Dokunmayı engellememesi için
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            color: themeColors.primary.withOpacity(0.4),
                            size: 32),
                        const SizedBox(height: 4),
                        Text("TARAMAK İÇİN\nKEŞFEDİN",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: themeColors.primary.withOpacity(0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          const Expanded(
              child: Text(
                  "Biletinizi okutmak için QR kodun üzerini parmağınızla temizleyin.",
                  style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _LargeEventImage extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _LargeEventImage({required this.imageUrl, required this.title});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;

    return Container(
      height: 240,
      margin: EdgeInsets.zero,
      // Biletin en dramatik, tek seferlik "hero" görseli — marka rengine
      // eğilen premium bir parlama.
      decoration: BoxDecoration(
        boxShadow: AppShadows.level5(themeColors.primary),
      ),
      child: Stack(
        children: [
          // Image - FULL WIDTH
          CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (final context, final url) => Container(
                height: 240,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeColors.surfaceVariant,
                    themeColors.surfaceContainer,
                  ],
                ))),
            errorWidget: (final context, final url, final error) => Container(
              height: 240,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                themeColors.surfaceVariant,
                themeColors.surfaceContainer
              ])),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded,
                      size: 64, color: themeColors.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.md),
                  Text('Görsel yüklenemedi',
                      style: context.textTheme.titleMedium
                          ?.copyWith(color: themeColors.onSurfaceVariant)),
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
                style: context.textTheme.headlineSmall?.copyWith(
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

/// Modal içindeki bilet detaylarını (koltuk, sahne, tarih vb.)
/// tek bir çerçeve içinde dikey bir liste olarak gösterir.
class _DetailsSection extends StatelessWidget {
  final DetailedTicket ticket;
  final String dateText;
  final String timeText;

  const _DetailsSection({
    required this.ticket,
    required this.dateText,
    required this.timeText,
  });

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Row(
          children: [
            Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        themeColors.primary,
                        themeColors.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xs)),
                child: Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 24)),
            const SizedBox(width: AppSpacing.md),
            Text('Bilet Bilgileri',
                style: context.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 22))
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // QR Kod stiline sahip yeni liste çerçevesi
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColors.surfaceContainer.withOpacity(0.8),
                themeColors.surfaceContainer.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: themeColors.primary, width: 1),
            boxShadow: AppShadows.level2(themeColors.shadow),
          ),
          child: Column(
            children: [
              _InfoListTile(
                  icon: Icons.event_seat_rounded,
                  title: 'Koltuk Numaraları',
                  subtitle: ticket.ticket.buySeats.join(", "),
                  isHighlighted: true),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.location_on_rounded,
                  title: 'Sahne',
                  subtitle: ticket.stage?.name ?? 'Yükleniyor...'),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'Tarih',
                  subtitle: dateText),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.access_time_filled_rounded,
                  title: 'Saat',
                  subtitle: timeText),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.payments_rounded,
                  title: 'Ödenen Tutar',
                  subtitle: '${ticket.ticket.orderPrice} TL',
                  isHighlighted: true),
              const _CustomDivider(),
              _InfoListTile(
                  icon: Icons.credit_card_rounded,
                  title: 'Ödeme Yöntemi',
                  subtitle: ticket.ticket.orderMethod,
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
  Widget build(final BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2)));
}

/// Dikey liste içindeki her bir yatay bilgi satırı.
class _InfoListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isHighlighted;
  final bool isLast;

  const _InfoListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isHighlighted = false,
    this.isLast = false,
  });

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    final themeText = context.textTheme;

    // İkonun "arka plan" rengini belirler
    final iconBackgroundColor =
        isHighlighted ? themeColors.primary : themeColors.tertiary;

    // Alt başlığın (değerin) rengini belirler
    final subtitleColor =
        isHighlighted ? themeColors.primary : themeColors.onSurface;

    return MergeSemantics(
      child: Semantics(
        label: '$title: $subtitle',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // İkon
            Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                    color: iconBackgroundColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Icon(icon, color: themeColors.primary, size: 24)),
            const SizedBox(width: AppSpacing.lg),

            // Başlık ve Alt Başlık
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(),
                      style: themeText.labelMedium?.copyWith(
                          color: themeColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: themeText.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: subtitleColor,
                          height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Biletten ilgili gösteriye ve/veya mekana geçiş yapılabilen aksiyon
/// bölümü. `show` ve/veya `stage` null olduğunda ilgili buton hiç
/// render edilmez; ikisi de null ise bölüm tamamen gizlenir (bkz.
/// [_LuxuryTicketDetails] içindeki koşullu render).
class _NavigationActionsSection extends StatelessWidget {
  final DetailedTicket ticket;

  const _NavigationActionsSection({required this.ticket});

  @override
  Widget build(final BuildContext context) {
    final show = ticket.show;
    final stage = ticket.stage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (show != null)
          _NavigationActionButton(
            icon: Icons.theater_comedy_rounded,
            label: 'Etkinliği Görüntüle',
            onTap: () {
              Navigator.pop(context);
              NavigationHandler.goToShow(context, show.id, show.name);
            },
          ),
        if (show != null && stage != null) const SizedBox(height: AppSpacing.md),
        if (stage != null)
          _NavigationActionButton(
            icon: Icons.location_on_rounded,
            label: 'Mekanı Görüntüle',
            onTap: () {
              Navigator.pop(context);
              NavigationHandler.goToStage(context, stage.id, stage.name);
            },
          ),
      ],
    );
  }
}

/// [_NavigationActionsSection] içinde kullanılan, modalın diğer
/// bölümleriyle aynı "lüks" gradyan/ikon diline sahip tek bir aksiyon
/// butonu.
class _NavigationActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColors.primary,
                  themeColors.primaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.level2(themeColors.primary),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
