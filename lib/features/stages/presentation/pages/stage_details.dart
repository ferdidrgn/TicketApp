import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../../shared/widgets/ticket/ticket_profile.dart';
import '../../../discovery/presentation/providers/nearby_events_provider.dart';
import '../../../settings/presentation/widgets/preference_widgets.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/detail/show_detail_skeleton.dart';
import '../../../shows/presentation/widgets/detail/show_programme.dart';
import '../../domain/entities/stage.dart';
import '../providers/stage_detail_provider.dart';

/// SAHNE SAYFASI — tiyatro programındaki "mekân" sayfası.
///
/// Kimlik bir künye biletidir (sahne fotoğrafı, ad, adres, KAPASİTE);
/// koçanda gerçek SIRADAKİ SEANS ve sayfanın TEK birincil aksiyonu
/// "Seansları gör". Program: Seanslar (bu sahnedeki yaklaşan seanslar,
/// tarih koçanlı bilet satırları) → Hakkında → Bu sahnede oynanan oyunlar
/// (bilet kartları) → Konum ve iletişim (harita + adres satırı yol tarifi
/// açar, telefon satırı arar).
///
/// Seanslar `upcomingNearbyEventsProvider`'dan (Show/Event/Stage birleşik,
/// `Event.showId` tek doğruluk kaynağı) bu sahnenin id'siyle süzülür —
/// yeni sorgu/provider yok.
class StageDetailPage extends ConsumerStatefulWidget {
  final String stageId;

  const StageDetailPage({super.key, required this.stageId});

  @override
  ConsumerState<StageDetailPage> createState() => _StageDetailPageState();
}

class _StageDetailPageState extends ConsumerState<StageDetailPage>
    with GlobalScrollMixin {
  final GlobalKey _sessionsKey = GlobalKey();

  @override
  void onLoadMore() {}

  @override
  Widget build(final BuildContext context) {
    final detailAsync = ref.watch(stageDetailProvider(widget.stageId));
    final bool twoPane =
        MediaQuery.sizeOf(context).width >= ResponsiveUtils.tabletBreakpoint;

    return ProfilePageShell(
      child: detailAsync.when(
        loading: () => ShowDetailSkeleton(twoPane: twoPane),
        error: (final err, final _) => ProfileErrorView(
          error: err,
          notFoundTitle: 'Bu sahne bulunamadı',
          failedTitle: 'Sahne bilgileri yüklenemedi',
          onRetry: () => ref.invalidate(stageDetailProvider(widget.stageId)),
        ),
        data: (final state) => _buildPage(context, state),
      ),
    );
  }

  Widget _buildPage(final BuildContext context, final StageDetailState state) {
    final Stage stage = state.stage;

    // Bu sahnedeki yaklaşan seanslar (tarih sırasıyla, gerçek veri).
    final sessionsAsync = ref.watch(upcomingNearbyEventsProvider);
    final List<NearbyEventEntry>? sessions = sessionsAsync.value
        ?.where((final e) => e.stage.id == stage.id)
        .toList();

    // Oyunlar: sahnenin `showsId` listesi, takviminde gelecek seansı olan
    // (aktif) oyunlar önce. Eskiden masaüstü aktif olmayanları gizliyor,
    // mobil hepsini gösteriyordu; artık ikisi de aynı, hiçbiri gizlenmiyor.
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

    final NearbyEventEntry? next =
        (sessions == null || sessions.isEmpty) ? null : sessions.first;
    final String capacity = stage.capacity.trim();

    return ProfileDetailLayout(
      controller: scrollController,
      footer: kIsWeb ? const Footer() : null,
      actions: const ProfileActionsRow(),
      ticket: (final layout) => ProfileTicket(
        layout: layout,
        kind: 'SAHNE',
        name: stage.name,
        imageUrl: stage.imageUrl,
        imageLabel: '${stage.name} fotoğrafı',
        placeholderIcon: Icons.theaters_rounded,
        tagline: stage.address,
        seed: stage.id,
        fields: [
          if (capacity.isNotEmpty)
            TicketField(
              label: 'KAPASİTE',
              value: RegExp(r'^\d+$').hasMatch(capacity)
                  ? '$capacity kişi'
                  : capacity,
            ),
        ],
        stubFields: [
          if (next != null) ...[
            TicketField(
              label: 'SIRADAKİ SEANS',
              value: '${next.dateTime.day} ${ticketMonthShort(next.dateTime)}, '
                  '${ticketTime(next.dateTime)}',
            ),
            TicketField(label: 'OYUN', value: next.show.name),
          ] else if (sessions != null)
            const TicketField(label: 'SEANS', value: 'Satışta seans yok'),
        ],
        action: next == null
            ? null
            : TicketStampButton(
                label: 'Seansları gör',
                leading: const Icon(Icons.event_seat_rounded),
                onTap: () => profileScrollTo(context, _sessionsKey),
              ),
      ),
      programme: (final compact) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyedSubtree(
            key: _sessionsKey,
            child: ProgrammeSection(
              title: 'Seanslar',
              meta: (sessions == null || sessions.isEmpty)
                  ? null
                  : '${sessions.length} seans',
              child: sessionsAsync.hasError && sessions == null
                  ? ProfileQuietNote(
                      icon: Icons.wifi_off_rounded,
                      text: 'Seanslar şu an getirilemedi. Bağlantını kontrol '
                          'edip tekrar dene.',
                      action: ProfileTextAction(
                        label: 'Tekrar dene',
                        icon: Icons.refresh_rounded,
                        onTap: () =>
                            ref.invalidate(upcomingNearbyEventsProvider),
                      ),
                    )
                  : sessions == null
                      ? const _SessionsSkeleton()
                      : sessions.isEmpty
                          ? ProfileQuietNote(
                              icon: Icons.event_busy_rounded,
                              text: 'Bu sahnede şu an satışta seans yok. '
                                  'Yeni seanslar eklendiğinde burada görünecek.',
                              action: ProfileTextAction(
                                label: 'Yakınımdaki seanslar',
                                onTap: () =>
                                    NavigationHandler.goToNearby(context),
                              ),
                            )
                          : _StageSessions(entries: sessions),
            ),
          ),
          if (stage.description.trim().isNotEmpty) ...[
            SizedBox(height: compact ? AppSpacing.huge : AppSpacing.section),
            ProgrammeSection(
              title: 'Hakkında',
              child: ShowStoryBlock(
                  text: stage.description.trim(), collapsible: compact),
            ),
          ],
          if (shows.isNotEmpty) ...[
            SizedBox(height: compact ? AppSpacing.huge : AppSpacing.section),
            ProgrammeSection(
              title: 'Bu sahnede oynanan oyunlar',
              meta: shows.length > 1 ? '${shows.length} oyun' : null,
              child: ProfileShowsBlock(shows: shows, compact: compact),
            ),
          ],
          SizedBox(height: compact ? AppSpacing.huge : AppSpacing.section),
          ProgrammeSection(
            title: 'Konum ve iletişim',
            child: _StageLocation(stage: stage, compact: compact),
          ),
        ],
      ),
    );
  }
}

/// Yaklaşan seanslar: tarih koçanlı bilet satırları. İlk 6, gerisi
/// "Tüm seansları göster" ile. Satır oyunun sayfasını açar (seans ve
/// koltuk seçimi orada).
class _StageSessions extends StatefulWidget {
  final List<NearbyEventEntry> entries;
  const _StageSessions({required this.entries});

  @override
  State<_StageSessions> createState() => _StageSessionsState();
}

class _StageSessionsState extends State<_StageSessions> {
  static const int _initialCount = 6;
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final entries = widget.entries;
    final int total = entries.length;
    final int visible =
        _expanded || total <= _initialCount ? total : _initialCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < visible; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          SessionTicketRow(
            key: ValueKey('stage-session-${entries[i].event.id}'),
            title: entries[i].show.name,
            dateTime: entries[i].dateTime,
            price: ticketPrice(entries[i].event.price),
            onTap: () => NavigationHandler.goToShow(
                context, entries[i].show.id, entries[i].show.name),
          ),
        ],
        if (total > _initialCount) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ProfileTextAction(
              label: _expanded
                  ? 'Daha az göster'
                  : 'Tüm seansları göster ($total)',
              icon: _expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
          ),
        ],
      ],
    );
  }
}

class _SessionsSkeleton extends StatelessWidget {
  const _SessionsSkeleton();

  @override
  Widget build(final BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TicketRowSkeleton(height: 88),
          SizedBox(height: AppSpacing.md),
          TicketRowSkeleton(height: 88),
          SizedBox(height: AppSpacing.md),
          TicketRowSkeleton(height: 88),
        ],
      );
}

/// Harita (koordinat girilmişse) + tek çerçeveli grupta adres ve iletişim
/// satırları. Adres satırı gerçek harita uygulamasında yol tarifini açar;
/// iletişim telefon numarasıysa arar.
class _StageLocation extends StatelessWidget {
  final Stage stage;
  final bool compact;

  const _StageLocation({required this.stage, required this.compact});

  bool get _hasCoordinates => stage.locationLat != 0 || stage.locationLng != 0;

  String get _mapsQuery {
    final String name = stage.name.trim();
    final String address = stage.address.trim();
    if (address.isEmpty) return name;
    if (name.isEmpty) return address;
    return '$name, $address';
  }

  /// Sadece rakam/boşluk/+/-/() içeren ve en az 10 rakamlı metin telefon
  /// sayılır; aksi hâlde (e-posta, serbest metin) sadece gösterilir.
  String? get _phone {
    final String raw = stage.communication.trim();
    if (!RegExp(r'^[\d\s+()\-]+$').hasMatch(raw)) return null;
    final String digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    return RegExp(r'\d').allMatches(digits).length >= 10 ? digits : null;
  }

  void _openDirections() {
    if (_hasCoordinates) {
      TiyatrolCommunicationActions.openStageLocation(
        lat: stage.locationLat,
        lng: stage.locationLng,
        stageName: stage.name,
      );
    } else {
      TiyatrolCommunicationActions.openAddressOnGoogleMaps(_mapsQuery);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final String address = stage.address.trim();
    final String contact = stage.communication.trim();
    final String? phone = _phone;
    final bool canDirect = _hasCoordinates || _mapsQuery.isNotEmpty;

    final rows = <Widget>[
      if (address.isNotEmpty || canDirect)
        PreferenceRow(
          icon: Icons.place_outlined,
          title: address.isNotEmpty ? address : stage.name,
          subtitle: 'Yol tarifi al',
          onTap: canDirect ? _openDirections : null,
          trailing: Icon(Icons.directions_rounded, color: colors.primary),
        ),
      if (contact.isNotEmpty)
        PreferenceRow(
          icon: Icons.phone_in_talk_outlined,
          title: contact,
          subtitle: phone != null ? 'Ara' : 'İletişim',
          onTap: phone == null
              ? null
              : () => launchUrl(Uri(scheme: 'tel', path: phone)),
          trailing: phone == null
              ? const SizedBox.shrink()
              : Icon(Icons.call_rounded, color: colors.primary),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasCoordinates) ...[
          Semantics(
            label: '${stage.name} haritada',
            child: Container(
              height: compact ? 220 : 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(stage.locationLat, stage.locationLng),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('stage'),
                      position: LatLng(stage.locationLat, stage.locationLng),
                    ),
                  },
                  zoomControlsEnabled: false,
                  // Sayfa kaydırmasıyla çakışmasın.
                  scrollGesturesEnabled: false,
                ),
              ),
            ),
          ),
          if (rows.isNotEmpty) const SizedBox(height: AppSpacing.lg),
        ],
        if (rows.isNotEmpty) PreferenceGroup(children: rows),
      ],
    );
  }
}
