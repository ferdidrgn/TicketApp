import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/sahne/sketch.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_profile.dart'
    show splitShowsByLiveActivity;
import '../../../../shared/widgets/ticket/web_profile_kit.dart';
import '../../../players/domain/entities/player.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../domain/entities/team.dart';
import '../providers/team_provider.dart';

/// TOPLULUK SAYFASI — WEB. "Künye ve program": solda yapışkan fildişi TOPLULUK
/// KÜNYESİ (görsel, durum damgası, sayılar, tek birincil aksiyon), sağda kayan
/// program (hakkında, sahnede olduğu oyunlar, kadro, galeri, geçmiş oyunlar).
/// Mobil "Sahne" deneyiminden (`TeamExperience`) AYRIDIR.
class TeamDetailPageWeb extends ConsumerWidget {
  final String teamId;
  const TeamDetailPageWeb({super.key, required this.teamId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final async = ref.watch(teamDetailProvider(teamId));
    final TeamDetailState? state = async.value;

    if (state == null) {
      return WebProfileFrame(
        barTitle: '',
        labels: const [],
        ready: false,
        placeholder: async.hasError
            ? WebProfileError(
                title: 'Topluluk yüklenemedi',
                onRetry: () => ref.invalidate(teamDetailProvider(teamId)),
              )
            : const WebProfileSkeleton(),
        aside: (_, __, ___) => const SizedBox.shrink(),
        program: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    final Team team = state.team;
    final split = splitShowsByLiveActivity(
      claimedActive: state.shows,
      past: const <Show>[],
      liveActive: ref.watch(activeShowsProvider(false)).value,
    );
    final List<Show> active = split.active;
    final List<Show> past = split.past;
    final List<Player> ensemble =
        ref.watch(teamEnsemblePlayersProvider(teamId)).value ??
            const <Player>[];
    final int castCount = state.ensemblePlayerIds.length;

    final String desc = team.description.replaceAll('\\n', '\n').trim();
    final List<String> photos = [
      if (team.imageUrl.trim().startsWith('http')) team.imageUrl.trim(),
      for (final String p in team.photosId)
        if (p.trim().startsWith('http') && p.trim() != team.imageUrl.trim())
          p.trim(),
    ];
    // Galeri: kapak hariç ek fotoğraflar; yoksa bölüm yok.
    final bool hasGallery = photos.length > 1;

    final List<String> labels = [
      'Hakkında',
      'Sahnede',
      if (castCount > 0) 'Kadro',
      if (hasGallery) 'Galeri',
      if (past.isNotEmpty) 'Geçmiş',
    ];

    return WebProfileFrame(
      barTitle: team.name,
      backdropUrl: team.imageUrl.startsWith('http') ? team.imageUrl : null,
      labels: labels,
      ready: true,
      aside: (final context, final keys, final entrance) => WebTicketEntrance(
        entrance: entrance,
        child: _TeamTicket(
          team: team,
          photos: photos,
          active: active.length,
          past: past.length,
          cast: castCount,
          onStage: active.isNotEmpty,
          onShows: () {
            if (active.length == 1) {
              HapticFeedback.mediumImpact();
              NavigationHandler.goToShow(
                  context, active.first.id, active.first.name,
                  imageUrl: active.first.imageUrl, title: active.first.name);
              return;
            }
            final BuildContext? c = keys[1].currentContext;
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
        int k = 2;
        final GlobalKey? castKey = castCount > 0 ? keys[k++] : null;
        final GlobalKey? galleryKey = hasGallery ? keys[k++] : null;
        final GlobalKey? pastKey = past.isNotEmpty ? keys[k++] : null;
        const SizedBox gap = SizedBox(height: 72);
        final ColorScheme cs = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WebCrumbs(current: 'Topluluklar'),
            const SizedBox(height: 26),
            WebWordTitle(text: team.name, entrance: entrance),
            const SizedBox(height: 14),
            SkSquiggle(width: 150, seed: team.name.length),
            if (active.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                  active.length == 1
                      ? 'şu an bir oyunuyla sahnede'
                      : 'şu an ${active.length} oyunuyla sahnede',
                  style: Sketch.hand(context, size: 30, color: cs.primary)),
            ],
            gap,
            WebSection(
              sectionKey: keys[0],
              title: 'Hakkında',
              subtitle: 'topluluğun hikâyesi',
              child: WebBio(
                  text: desc.isEmpty
                      ? 'Bu topluluk için henüz bir tanıtım eklenmemiş.'
                      : desc),
            ),
            gap,
            WebSection(
              sectionKey: keys[1],
              title: 'Sahnede',
              subtitle: active.isEmpty
                  ? 'şu an oyunu yok'
                  : '${active.length} oyunda sahnede',
              child: active.isEmpty
                  ? WebQuietNote(
                      text: 'Topluluğun şu an sahnede olan bir oyunu yok. '
                          'Yeni oyunlar eklendiğinde burada görünecek.',
                      actionLabel: past.isEmpty ? null : 'Geçmiş oyunlara bak',
                      onAction: past.isEmpty
                          ? null
                          : () {
                              final BuildContext? c =
                                  pastKey?.currentContext;
                              if (c != null) {
                                Scrollable.ensureVisible(c,
                                    duration: AppMotion.normal,
                                    curve: Curves.easeInOutCubic,
                                    alignment: 0.04);
                              }
                            },
                    )
                  : WebPosterRail(shows: active),
            ),
            if (castKey != null) ...[
              gap,
              WebSection(
                sectionKey: castKey,
                title: 'Kadro',
                subtitle: '$castCount oyuncu, dokun ve tanış',
                child: ensemble.isEmpty
                    ? const _CastSkeleton()
                    : _CastGrid(players: ensemble),
              ),
            ],
            if (galleryKey != null) ...[
              gap,
              WebSection(
                sectionKey: galleryKey,
                title: 'Galeri',
                subtitle: '${photos.length} fotoğraf',
                child: WebGallery(photos: photos),
              ),
            ],
            if (pastKey != null) ...[
              gap,
              WebSection(
                sectionKey: pastKey,
                title: 'Geçmiş oyunlar',
                subtitle: '${past.length} oyun',
                child: WebPastGrid(shows: past),
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

class _TeamTicket extends StatelessWidget {
  final Team team;
  final List<String> photos;
  final int active;
  final int past;
  final int cast;
  final bool onStage;
  final VoidCallback onShows;

  const _TeamTicket({
    required this.team,
    required this.photos,
    required this.active,
    required this.past,
    required this.cast,
    required this.onStage,
    required this.onShows,
  });

  @override
  Widget build(final BuildContext context) {
    final bool reduce = Sk.reduceMotion(context);
    final bool hasPhoto = photos.isNotEmpty;

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
            const TicketHeaderStrip(kind: 'TOPLULUK KÜNYESİ'),
            const SizedBox(height: 16),
            MouseRegion(
              cursor: hasPhoto ? SystemMouseCursors.zoomIn : MouseCursor.defer,
              child: GestureDetector(
                onTap: hasPhoto
                    ? () => GalleryViewerDialog.open(context, photos)
                    : null,
                child: Semantics(
                  label: '${team.name} görseli',
                  image: true,
                  child: WebTiltImage(
                    url: team.imageUrl,
                    aspectRatio: 1,
                    topRadius: 120,
                    fallbackIcon: Icons.groups_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(team.name, style: TicketInk.headline(30)),
            const SizedBox(height: 10),
            Row(children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: onStage
                            ? TicketInk.accentOf(context)
                            : TicketInk.inkSoft(0.4),
                        width: 1.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(onStage ? 'ŞU AN SAHNEDE' : 'SAHNEYE ARA VERDİ',
                      style: TextStyle(
                          color: onStage
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
              count('SAHNEDE', active),
              count('GEÇMİŞ', past),
              count('KADRO', cast),
            ]),
            const SizedBox(height: 18),
            const SizedBox(height: 2, child: TicketPerforation()),
            const SizedBox(height: 16),
            if (onStage) ...[
              TicketStampButton(
                label: active == 1 ? 'Oyuna git' : 'Oyunlarını gör',
                leading: const Icon(Icons.event_seat_rounded, size: 18),
                onTap: onShows,
              ),
              Align(
                alignment: Alignment.center,
                child: TicketTextLink(
                  label: 'Paylaş',
                  onTap: () => TiyatrolDeeplinkService.shareTeam(
                      id: team.id, name: team.name),
                ),
              ),
            ] else
              TicketStampButton(
                label: 'Paylaş',
                leading: const Icon(Icons.ios_share_rounded, size: 18),
                onTap: () => TiyatrolDeeplinkService.shareTeam(
                    id: team.id, name: team.name),
              ),
            const SizedBox(height: 12),
            TicketBarcode(seed: team.id, height: 34),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KADRO
// ═════════════════════════════════════════════════════════════════════════════

class _CastSkeleton extends StatelessWidget {
  const _CastSkeleton();

  @override
  Widget build(final BuildContext context) => Wrap(
        spacing: 22,
        runSpacing: 22,
        children: [
          for (int i = 0; i < 5; i++)
            const SkBone(width: 120, height: 150, radius: 60),
        ],
      );
}

class _CastGrid extends StatelessWidget {
  final List<Player> players;
  const _CastGrid({required this.players});

  @override
  Widget build(final BuildContext context) => Wrap(
        spacing: 26,
        runSpacing: 28,
        children: [for (final Player p in players) _CastTile(player: p)],
      );
}

class _CastTile extends StatefulWidget {
  final Player player;
  const _CastTile({required this.player});

  @override
  State<_CastTile> createState() => _CastTileState();
}

class _CastTileState extends State<_CastTile> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Player p = widget.player;
    final String name = '${p.firstName} ${p.lastName}'.trim();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        semanticLabel: '$name oyuncu sayfasını aç',
        onTap: () => NavigationHandler.goToPlayer(context, p.id, name,
            imageUrl: p.imageUrl, title: name),
        child: SizedBox(
          width: 132,
          child: Column(children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _hover ? cs.primary : Colors.transparent, width: 2.4),
                boxShadow: skSoftShadow(context, strength: _hover ? 1.2 : 0.7),
              ),
              child: ClipOval(
                child: SkImage(
                    url: p.imageUrl,
                    alignment: const Alignment(0, -0.35),
                    fallbackIcon: Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Sk.ui(context,
                    size: 14.5,
                    weight: FontWeight.w800,
                    height: 1.25,
                    color: _hover ? cs.primary : cs.onSurface)),
          ]),
        ),
      ),
    );
  }
}
