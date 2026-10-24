import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/sahne/sketch.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../../shared/widgets/ticket/web_profile_kit.dart';
import '../../../discovery/presentation/providers/nearby_events_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../domain/entities/stage.dart';
import '../providers/stage_detail_provider.dart';

/// SAHNE SAYFASI — WEB. "Künye ve program": solda yapışkan fildişi SAHNE
/// KÜNYESİ (fotoğraf, durum damgası, kapasite, sıradaki seans, tek birincil
/// aksiyon "Seansları gör"), sağda kayan program (seanslar tablosu, hakkında,
/// bu sahnede oynanan oyunlar, konum ve iletişim). Mobil sayfadan AYRIDIR.
///
/// Seanslar `upcomingNearbyEventsProvider`'dan bu sahnenin id'siyle süzülür
/// (`Event.showId` tek doğruluk kaynağı) — yeni sorgu/provider yok.
class StageDetailPageWeb extends ConsumerWidget {
  final String stageId;
  const StageDetailPageWeb({super.key, required this.stageId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final async = ref.watch(stageDetailProvider(stageId));
    final StageDetailState? state = async.value;

    if (state == null) {
      return WebProfileFrame(
        barTitle: '',
        labels: const [],
        ready: false,
        placeholder: async.hasError
            ? WebProfileError(
                title: 'Sahne yüklenemedi',
                onRetry: () => ref.invalidate(stageDetailProvider(stageId)),
              )
            : const WebProfileSkeleton(),
        aside: (_, __, ___) => const SizedBox.shrink(),
        program: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    final Stage stage = state.stage;
    final sessionsAsync = ref.watch(upcomingNearbyEventsProvider);
    final List<NearbyEventEntry>? sessions = sessionsAsync.value
        ?.where((final e) => e.stage.id == stage.id)
        .toList();

    // Gelecek seansı olan (aktif) oyunlar önce; hiçbiri gizlenmez.
    final Set<String>? liveIds = ref
        .watch(activeShowsProvider(false))
        .value
        ?.map((final s) => s.id)
        .toSet();
    final List<Show> shows = liveIds == null
        ? state.shows
        : [
            ...state.shows.where((final s) => liveIds.contains(s.id)),
            ...state.shows.where((final s) => !liveIds.contains(s.id)),
          ];

    final String desc = stage.description.replaceAll('\\n', '\n').trim();
    final bool hasPlace = stage.address.trim().isNotEmpty ||
        stage.communication.trim().isNotEmpty ||
        stage.locationLat != 0 ||
        stage.locationLng != 0;

    // Bölüm sırası = çubuk sırası; yalnızca var olanlar.
    final List<String> labels = [
      'Seanslar',
      if (desc.isNotEmpty) 'Hakkında',
      if (shows.isNotEmpty) 'Oyunlar',
      if (hasPlace) 'Konum',
    ];

    final NearbyEventEntry? next =
        (sessions == null || sessions.isEmpty) ? null : sessions.first;

    return WebProfileFrame(
      barTitle: stage.name,
      backdropUrl: stage.imageUrl.startsWith('http') ? stage.imageUrl : null,
      labels: labels,
      ready: true,
      aside: (final context, final keys, final entrance) => WebTicketEntrance(
        entrance: entrance,
        child: _StageTicket(
          stage: stage,
          next: next,
          sessionCount: sessions?.length,
          showCount: shows.length,
          photos: [
            if (stage.imageUrl.trim().startsWith('http')) stage.imageUrl.trim(),
          ],
          onSessions: () {
            final BuildContext? c = keys[0].currentContext;
            if (c != null) {
              HapticFeedback.mediumImpact();
              Scrollable.ensureVisible(c,
                  duration: Sk.reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  alignment: 0.04);
            }
          },
        ),
      ),
      program: (final context, final keys, final entrance) {
        int k = 0;
        final GlobalKey sessionsKey = keys[k++];
        final GlobalKey? aboutKey = desc.isNotEmpty ? keys[k++] : null;
        final GlobalKey? showsKey = shows.isNotEmpty ? keys[k++] : null;
        final GlobalKey? placeKey = hasPlace ? keys[k++] : null;
        const SizedBox gap = SizedBox(height: 72);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WebCrumbs(current: 'Sahneler'),
            const SizedBox(height: 26),
            WebWordTitle(text: stage.name, entrance: entrance),
            const SizedBox(height: 14),
            SkSquiggle(width: 150, seed: stage.name.length),
            if (stage.address.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(stage.address.trim(),
                  style: Sketch.hand(context,
                      size: 30, color: Theme.of(context).colorScheme.primary)),
            ],
            gap,
            WebSection(
              sectionKey: sessionsKey,
              title: 'Seanslar',
              subtitle: sessions == null
                  ? 'yükleniyor'
                  : sessions.isEmpty
                      ? 'şu an satışta seans yok'
                      : '${sessions.length} yaklaşan seans',
              child: sessionsAsync.hasError && sessions == null
                  ? WebQuietNote(
                      text: 'Seanslar şu an getirilemedi. Bağlantını kontrol '
                          'edip tekrar dene.',
                      actionLabel: 'Tekrar dene',
                      onAction: () =>
                          ref.invalidate(upcomingNearbyEventsProvider),
                    )
                  : sessions == null
                      ? const _SessionsSkeleton()
                      : sessions.isEmpty
                          ? WebQuietNote(
                              text: 'Bu sahnede şu an satışta seans yok. Yeni '
                                  'seanslar eklendiğinde burada görünecek.',
                              actionLabel: 'Yakınımdaki seanslar',
                              onAction: () =>
                                  NavigationHandler.goToNearby(context),
                            )
                          : _SessionsTable(entries: sessions),
            ),
            if (aboutKey != null) ...[
              gap,
              WebSection(
                sectionKey: aboutKey,
                title: 'Hakkında',
                subtitle: 'sahne hakkında kısa bir not',
                child: WebBio(text: desc),
              ),
            ],
            if (showsKey != null) ...[
              gap,
              WebSection(
                sectionKey: showsKey,
                title: 'Bu sahnede oynanan oyunlar',
                subtitle: '${shows.length} oyun',
                child: WebPosterRail(shows: shows),
              ),
            ],
            if (placeKey != null) ...[
              gap,
              WebSection(
                sectionKey: placeKey,
                title: 'Konum ve iletişim',
                subtitle: 'yol tarifi tek dokunuşla',
                child: _StageLocation(stage: stage),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KÜNYE BİLETİ
// ═════════════════════════════════════════════════════════════════════════════

class _StageTicket extends StatelessWidget {
  final Stage stage;
  final NearbyEventEntry? next;
  final int? sessionCount;
  final int showCount;
  final List<String> photos;
  final VoidCallback onSessions;

  const _StageTicket({
    required this.stage,
    required this.next,
    required this.sessionCount,
    required this.showCount,
    required this.photos,
    required this.onSessions,
  });

  @override
  Widget build(final BuildContext context) {
    final bool reduce = Sk.reduceMotion(context);
    final bool hasPhoto = photos.isNotEmpty;
    final bool onSale = (sessionCount ?? 0) > 0;
    final String capacity = stage.capacity.trim();

    Widget count(final String label, final int n) => Expanded(
          child: TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: n),
            duration:
                reduce ? Duration.zero : const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, final v, __) =>
                TicketField(label: label, value: '$v'),
          ),
        );

    return TicketPiece(
      perforated: TicketEdge.bottom,
      notch: 16,
      corner: 22,
      shadows: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 44,
            offset: const Offset(0, 22)),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const TicketHeaderStrip(kind: 'SAHNE KÜNYESİ'),
            const SizedBox(height: 16),
            MouseRegion(
              cursor: hasPhoto ? SystemMouseCursors.zoomIn : MouseCursor.defer,
              child: GestureDetector(
                onTap: hasPhoto
                    ? () => GalleryViewerDialog.open(context, photos)
                    : null,
                child: Semantics(
                  label: '${stage.name} fotoğrafı',
                  image: true,
                  child: WebTiltImage(
                    url: stage.imageUrl,
                    aspectRatio: 4 / 3,
                    topRadius: 18,
                    fallbackIcon: Icons.theaters_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(stage.name, style: TicketInk.headline(30)),
            const SizedBox(height: 10),
            Row(children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: onSale
                            ? TicketInk.accentOf(context)
                            : TicketInk.inkSoft(0.4),
                        width: 1.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(onSale ? 'SEANSLAR SATIŞTA' : 'ŞU AN SEANS YOK',
                      style: TextStyle(
                          color: onSale
                              ? TicketInk.accentOf(context)
                              : TicketInk.inkSoft(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8)),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              count('SEANS', sessionCount ?? 0),
              count('OYUN', showCount),
              if (capacity.isNotEmpty)
                Expanded(
                  child: TicketField(
                    label: 'KAPASİTE',
                    value: RegExp(r'^\d+$').hasMatch(capacity)
                        ? '$capacity kişi'
                        : capacity,
                  ),
                ),
            ]),
            if (next != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TicketField(
                    label: 'SIRADAKİ SEANS',
                    value: '${next!.dateTime.day} '
                        '${ticketMonthShort(next!.dateTime)}, '
                        '${ticketTime(next!.dateTime)}',
                  ),
                ),
                Expanded(
                    child: TicketField(label: 'OYUN', value: next!.show.name)),
              ]),
            ],
            const SizedBox(height: 18),
            const SizedBox(height: 2, child: TicketPerforation()),
            const SizedBox(height: 16),
            if (next != null)
              TicketStampButton(
                label: 'Seansları gör',
                leading: const Icon(Icons.event_seat_rounded, size: 18),
                onTap: onSessions,
              )
            else
              TicketStampButton(
                label: 'Yol tarifi al',
                leading: const Icon(Icons.directions_rounded, size: 18),
                onTap: () => _openDirections(stage),
              ),
            const SizedBox(height: 16),
            TicketBarcode(seed: stage.id, height: 34),
          ],
        ),
      ),
    );
  }
}

bool _hasCoordinates(final Stage s) => s.locationLat != 0 || s.locationLng != 0;

void _openDirections(final Stage stage) {
  if (_hasCoordinates(stage)) {
    TiyatrolCommunicationActions.openStageLocation(
      lat: stage.locationLat,
      lng: stage.locationLng,
      stageName: stage.name,
    );
    return;
  }
  final String name = stage.name.trim();
  final String address = stage.address.trim();
  TiyatrolCommunicationActions.openAddressOnGoogleMaps(
      address.isEmpty ? name : '$name, $address');
}

// ═════════════════════════════════════════════════════════════════════════════
// SEANSLAR
// ═════════════════════════════════════════════════════════════════════════════

/// Seanslar tablosu: tarih · oyun/gün-saat · fiyat · "Bilet al". İlk 8, gerisi
/// "Tüm seansları göster" ile. Satır oyunun sayfasını açar (koltuk orada).
class _SessionsTable extends StatefulWidget {
  final List<NearbyEventEntry> entries;
  const _SessionsTable({required this.entries});

  @override
  State<_SessionsTable> createState() => _SessionsTableState();
}

class _SessionsTableState extends State<_SessionsTable> {
  static const int _initial = 8;
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final entries = widget.entries;
    final int total = entries.length;
    final int visible = _expanded || total <= _initial ? total : _initial;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < visible; i++)
          _SessionRow(
            key: ValueKey('stage-web-session-${entries[i].event.id}'),
            entry: entries[i],
          ),
        if (total > _initial)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20),
              label:
                  Text(_expanded ? 'Daha az göster' : 'Tüm seansları göster ($total)'),
            ),
          ),
      ],
    );
  }
}

class _SessionRow extends StatefulWidget {
  final NearbyEventEntry entry;
  const _SessionRow({super.key, required this.entry});

  @override
  State<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<_SessionRow> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime d = widget.entry.dateTime;
    final Show show = widget.entry.show;
    final String price = ticketPrice(widget.entry.event.price) ?? '';
    final bool narrow = MediaQuery.sizeOf(context).width < 640;

    final Widget dateBlock = SizedBox(
      width: 64,
      child: Column(children: [
        Text('${d.day}',
            style: Sk.display(context, size: 38, height: 1.0, color: cs.primary)),
        Text(kMonthsTr[d.month - 1],
            style: Sk.ui(context,
                size: 13, color: cs.onSurfaceVariant, weight: FontWeight.w700)),
      ]),
    );
    final Widget info = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(show.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Sk.ui(context, size: 17, weight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text('${kDaysTr[d.weekday - 1]} · ${skClock(d)}',
              style: Sk.ui(context,
                  size: 14,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w600)),
        ]);
    final Widget cta = Row(mainAxisSize: MainAxisSize.min, children: [
      if (price.isNotEmpty)
        Text(price, style: Sk.display(context, size: 22, height: 1.0)),
      const SizedBox(width: 14),
      AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hover ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: cs.primary, width: 1.6),
        ),
        child: Text('Bilet al',
            style: Sk.ui(context,
                size: 13.5,
                weight: FontWeight.w800,
                color: _hover ? cs.onPrimary : cs.primary)),
      ),
    ]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: PressScale(
          semanticLabel:
              '${show.name}, ${d.day} ${kMonthsTr[d.month - 1]} ${skClock(d)}, bilet al',
          onTap: () => NavigationHandler.goToShow(context, show.id, show.name,
              imageUrl: show.imageUrl, title: show.name),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              color: _hover ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        dateBlock,
                        const SizedBox(width: 16),
                        Expanded(child: info),
                      ]),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerRight, child: cta),
                    ],
                  )
                : Row(children: [
                    dateBlock,
                    const SizedBox(width: 22),
                    Expanded(child: info),
                    const SizedBox(width: 16),
                    cta,
                  ]),
          ),
        ),
      ),
    );
  }
}

class _SessionsSkeleton extends StatelessWidget {
  const _SessionsSkeleton();

  @override
  Widget build(final BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkBone(height: 84, radius: 24),
          SizedBox(height: AppSpacing.md),
          SkBone(height: 84, radius: 24),
          SizedBox(height: AppSpacing.md),
          SkBone(height: 84, radius: 24),
        ],
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// KONUM VE İLETİŞİM
// ═════════════════════════════════════════════════════════════════════════════

class _StageLocation extends StatelessWidget {
  final Stage stage;
  const _StageLocation({required this.stage});

  /// En az 10 rakamlı, yalnızca rakam/boşluk/+/-/() içeren metin telefon sayılır.
  String? get _phone {
    final String raw = stage.communication.trim();
    if (!RegExp(r'^[\d\s+()\-]+$').hasMatch(raw)) return null;
    final String digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    return RegExp(r'\d').allMatches(digits).length >= 10 ? digits : null;
  }

  @override
  Widget build(final BuildContext context) {
    final String address = stage.address.trim();
    final String contact = stage.communication.trim();
    final String? phone = _phone;
    final bool hasMap = _hasCoordinates(stage);
    final bool canDirect = hasMap || address.isNotEmpty || stage.name.isNotEmpty;

    final List<Widget> rows = [
      if (address.isNotEmpty || canDirect)
        WebInfoRow(
          icon: Icons.place_outlined,
          title: address.isNotEmpty ? address : stage.name,
          subtitle: 'Yol tarifi al',
          trailing: Icons.directions_rounded,
          onTap: canDirect ? () => _openDirections(stage) : null,
        ),
      if (contact.isNotEmpty)
        WebInfoRow(
          icon: Icons.phone_in_talk_outlined,
          title: contact,
          subtitle: phone != null ? 'Ara' : 'İletişim',
          trailing: Icons.call_rounded,
          onTap: phone == null
              ? null
              : () => launchUrl(Uri(scheme: 'tel', path: phone)),
        ),
    ];

    final Widget info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          rows[i],
        ],
      ],
    );

    return LayoutBuilder(builder: (final context, final box) {
      final Widget? map = hasMap
          ? Semantics(
              label: '${stage.name} haritada',
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(stage.locationLat, stage.locationLng),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('stage'),
                        position:
                            LatLng(stage.locationLat, stage.locationLng),
                      ),
                    },
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                ),
              ),
            )
          : null;
      if (map == null) {
        return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640), child: info);
      }
      if (box.maxWidth >= 860) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 6, child: map),
          const SizedBox(width: 28),
          Expanded(flex: 5, child: info),
        ]);
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [map, const SizedBox(height: 20), info]);
    });
  }
}
