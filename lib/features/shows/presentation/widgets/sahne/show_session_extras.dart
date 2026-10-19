import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/util/calendar_actions.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../detail/show_detail_data.dart';

/// "3 gün sonra", "Yarın akşam", "Bu gece" — gerçek seans zamanından, sayaçsız.
String sessionWhenPhrase(final DateTime when) {
  final DateTime now = DateTime.now();
  final Duration left = when.difference(now);
  if (left.isNegative) return 'Perde açıldı';
  final int days = skDay(when).difference(skDay(now)).inDays;
  String part() {
    final int h = when.hour;
    if (h < 12) return 'sabah';
    if (h < 17) return 'öğleden sonra';
    if (h < 21) return 'akşam';
    return 'gece';
  }

  if (days == 0) return left.inMinutes < 180 ? 'Az kaldı' : 'Bugün ${part()}';
  if (days == 1) return 'Yarın ${part()}';
  if (days < 7) return '$days gün sonra';
  if (days < 30) return '${(days / 7).round()} hafta sonra';
  return '${(days / 30).round()} ay sonra';
}

/// Sahnenin haritada açılması (koordinat yoksa ad + adres araması).
Future<void> openStageDirections(final Stage s) async {
  HapticFeedback.lightImpact();
  final bool hasGeo = s.locationLat != 0 || s.locationLng != 0;
  final Uri uri = Uri.parse(hasGeo
      ? 'https://www.google.com/maps/search/?api=1&query=${s.locationLat},${s.locationLng}'
      : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${s.name} ${s.address}')}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Seansı cihaz takvimine ekler.
Future<void> addSessionToCalendar(
    final ShowSession s, final String showName, final String duration) async {
  final DateTime? when = s.when;
  if (when == null) return;
  HapticFeedback.selectionClick();
  await TiyatrolCalendarActions.addShowEventToCalendar(
    showName: showName,
    eventStart: when,
    location: [s.venueName, s.stage?.address ?? '']
        .where((final p) => p.trim().isNotEmpty)
        .join(', '),
    showDuration: duration,
  );
}

/// Küçük, sakin iki eylem: Takvime ekle · Yol tarifi.
class SessionActions extends StatelessWidget {
  final ShowSession session;
  final String showName;
  final String duration;

  const SessionActions({
    super.key,
    required this.session,
    required this.showName,
    this.duration = '',
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Widget action(final IconData icon, final String label,
            final VoidCallback onTap) =>
        PressScale(
          onTap: onTap,
          semanticLabel: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(label,
                    style: Sk.ui(context,
                        size: 12.5,
                        color: cs.primary,
                        weight: FontWeight.w800)),
              ],
            ),
          ),
        );
    final Stage? stage = session.stage;
    return Wrap(
      spacing: AppSpacing.md,
      children: [
        if (session.when != null)
          action(Icons.event_available_rounded, 'Takvime ekle',
              () => addSessionToCalendar(session, showName, duration)),
        if (stage != null)
          action(Icons.directions_rounded, 'Yol tarifi',
              () => openStageDirections(stage)),
      ],
    );
  }
}

/// Harici (başka platformda biletli) oyunun seans listesi: gün/saat/sahne +
/// zaman ifadesi + eylemler. Bilet satın alma alt çubuktaki tek aksiyondur.
class ExternalSessionList extends StatelessWidget {
  final ShowDetailData data;
  const ExternalSessionList({super.key, required this.data});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<ShowSession> upcoming = [
      for (final ShowSession s in data.sessions)
        if (s.when == null || s.when!.isAfter(DateTime.now())) s,
    ];
    if (upcoming.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        SkSectionHead(
          title: 'Tarihler',
          subtitle:
              '${upcoming.length} seans · bilet iş ortağımızın sayfasında',
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < upcoming.length; i++)
          Reveal(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: _ExternalRow(
                  session: upcoming[i],
                  showName: data.show.name,
                  duration: data.show.duration,
                  cs: cs),
            ),
          ),
      ],
    );
  }
}

class _ExternalRow extends StatelessWidget {
  final ShowSession session;
  final String showName;
  final String duration;
  final ColorScheme cs;

  const _ExternalRow({
    required this.session,
    required this.showName,
    required this.duration,
    required this.cs,
  });

  @override
  Widget build(final BuildContext context) {
    final DateTime? when = session.when;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(when == null ? session.shortLabel : skClock(when),
                      style: Sk.display(context,
                          size: 26, height: 1.0, color: cs.primary)),
                  if (when != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                          '${kDaysTr[when.weekday - 1]}, ${when.day} ${kMonthsTr[when.month - 1]}',
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.venueName.isNotEmpty)
                      Text(session.venueName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 14, weight: FontWeight.w800, height: 1.2)),
                    if ((session.stage?.address ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(session.stage!.address.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Sk.ui(context,
                                size: 12,
                                color: cs.onSurfaceVariant,
                                weight: FontWeight.w500)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SessionActions(
                    session: session, showName: showName, duration: duration),
              ),
              if (when != null) SkBadge(label: sessionWhenPhrase(when)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seansların fiyat aralığı + en yakın / en uygun seans — gerçek veriden.
/// Uygulama içi biletli oyunlarda "Seanslar"ın üstünde tek satırlık özet.
class SessionInsight extends StatelessWidget {
  final ShowDetailData data;
  final ValueChanged<ShowSession> onPick;

  const SessionInsight({super.key, required this.data, required this.onPick});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime now = DateTime.now();
    final List<ShowSession> future = [
      for (final ShowSession s in data.sessions)
        if (s.when != null && s.when!.isAfter(now)) s,
    ];
    if (future.length < 2) return const SizedBox.shrink();
    future.sort((a, b) => a.when!.compareTo(b.when!));
    final ShowSession nearest = future.first;
    final List<ShowSession> priced = [
      for (final ShowSession s in future)
        if (s.price != null && s.price! > 0) s,
    ];
    ShowSession? cheapest;
    if (priced.length >= 2) {
      priced.sort((a, b) => a.price!.compareTo(b.price!));
      if (priced.first.price! < priced.last.price!) cheapest = priced.first;
    }

    Widget tile(final String label, final String top, final String sub,
            final ShowSession s) =>
        Expanded(
          child: PressScale(
            onTap: () => onPick(s),
            semanticLabel: '$label: $top, $sub',
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Sk.ui(context,
                          size: 11.5,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(top,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 15, weight: FontWeight.w800, height: 1.2)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 12,
                          color: cs.primary,
                          weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          tile('En yakın', skDateTime(nearest.when!),
              sessionWhenPhrase(nearest.when!), nearest),
          if (cheapest != null) ...[
            const SizedBox(width: AppSpacing.sm + 2),
            tile('En uygun', skPrice(cheapest.price!),
                skDateTime(cheapest.when!), cheapest),
          ],
        ],
      ),
    );
  }
}
