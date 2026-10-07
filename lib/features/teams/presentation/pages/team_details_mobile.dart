import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_profile.dart';
import '../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/detail/show_detail_skeleton.dart';
import '../../../shows/presentation/widgets/detail/show_programme.dart';
import '../../domain/entities/team.dart';
import '../providers/team_provider.dart';

/// TOPLULUK SAYFASI — tiyatro programındaki "prodüksiyon / topluluk"
/// künyesi. (Dosya adı tarihsel: router web ve mobilde bu tek sayfayı
/// kullanır; kompozisyonu genişlik belirler — bkz. `ProfileDetailLayout`.)
///
/// Kimlik bir künye biletidir (topluluk görseli + ad); koçanda TEK
/// birincil aksiyon: sahnedeki oyununa git / sahnedeki oyunlarına in.
/// Program: Sahnede (bilet kartları) → Hikâye → Geçmiş oyunlar →
/// Fotoğraflar. Oyunlar `Team.showsId`'den gelir ve canlı takvimle
/// (`activeShowsProvider`) sahnede / geçmiş diye ayrılır.
class TeamDetailsPage extends ConsumerStatefulWidget {
  final String teamId;

  const TeamDetailsPage({super.key, required this.teamId});

  @override
  ConsumerState<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends ConsumerState<TeamDetailsPage>
    with GlobalScrollMixin {
  final GlobalKey _onStageKey = GlobalKey();

  @override
  void onLoadMore() {}

  @override
  Widget build(final BuildContext context) {
    final teamDetailAsync = ref.watch(teamDetailProvider(widget.teamId));
    final bool twoPane =
        MediaQuery.sizeOf(context).width >= ResponsiveUtils.tabletBreakpoint;

    return ProfilePageShell(
      child: teamDetailAsync.when(
        loading: () => ShowDetailSkeleton(twoPane: twoPane),
        error: (final err, final _) => ProfileErrorView(
          error: err,
          notFoundTitle: 'Bu topluluk bulunamadı',
          failedTitle: 'Topluluk bilgileri yüklenemedi',
          onRetry: () => ref.invalidate(teamDetailProvider(widget.teamId)),
        ),
        data: (final state) => _buildPage(context, state),
      ),
    );
  }

  Widget _buildPage(final BuildContext context, final TeamDetailState state) {
    final Team team = state.team;
    final split = splitShowsByLiveActivity(
      claimedActive: state.shows,
      past: const <Show>[],
      liveActive: ref.watch(activeShowsProvider(false)).value,
    );

    return ProfileDetailLayout(
      controller: scrollController,
      footer: kIsWeb ? const Footer() : null,
      actions: ProfileActionsRow(
        shareLabel: 'Topluluğu paylaş',
        onShare: () =>
            TiyatrolDeeplinkService.shareTeam(id: team.id, name: team.name),
      ),
      ticket: (final layout) => ProfileTicket(
        layout: layout,
        kind: 'TOPLULUK',
        name: team.name,
        heroTag: resolveTiyatrolHeroTag(
            context, TiyatrolHeroTags.team(team.id)),
        imageUrl: team.imageUrl,
        imageLabel: '${team.name} görseli',
        placeholderIcon: Icons.groups_2_rounded,
        seed: team.id,
        stubFields: [
          if (state.shows.isNotEmpty)
            TicketField(
              label: 'ŞU AN SAHNEDE',
              value: switch (split.active.length) {
                0 => 'Sahnede oyunu yok',
                1 => split.active.first.name,
                _ => '${split.active.length} oyun',
              },
            ),
        ],
        action: _primaryAction(context, split.active),
      ),
      programme: (final compact) => _Programme(
        team: team,
        activeShows: split.active,
        pastShows: split.past,
        compact: compact,
        onStageKey: _onStageKey,
      ),
    );
  }

  Widget? _primaryAction(final BuildContext context, final List<Show> active) {
    if (active.isEmpty) return null;
    if (active.length == 1) {
      final Show show = active.first;
      return TicketStampButton(
        label: 'Oyuna git',
        leading: const Icon(Icons.theater_comedy_rounded),
        onTap: () => NavigationHandler.goToShow(context, show.id, show.name),
      );
    }
    return TicketStampButton(
      label: 'Oyunlarını gör',
      leading: const Icon(Icons.theater_comedy_rounded),
      onTap: () => profileScrollTo(context, _onStageKey),
    );
  }
}

class _Programme extends StatelessWidget {
  final Team team;
  final List<Show> activeShows;
  final List<Show> pastShows;
  final bool compact;
  final GlobalKey onStageKey;

  const _Programme({
    required this.team,
    required this.activeShows,
    required this.pastShows,
    required this.compact,
    required this.onStageKey,
  });

  @override
  Widget build(final BuildContext context) {
    final double gap = compact ? AppSpacing.huge : AppSpacing.section;
    // Firestore'a elle girilen metinlerde "\n" kaçışlı gelebiliyor.
    final String story = team.description.replaceAll('\\n', '\n').trim();
    final bool nothingLinked = activeShows.isEmpty && pastShows.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: onStageKey,
          child: ProgrammeSection(
            title: 'Sahnede',
            meta: activeShows.length > 1 ? '${activeShows.length} oyun' : null,
            child: activeShows.isNotEmpty
                ? ProfileShowsBlock(shows: activeShows, compact: compact)
                : ProfileQuietNote(
                    icon: Icons.event_busy_rounded,
                    text: nothingLinked
                        ? 'Topluluğun şu an sahnede bir oyunu yok.'
                        : 'Topluluğun şu an sahnede bir oyunu yok. Sahnelediği '
                            'oyunlar aşağıda.',
                    action: nothingLinked
                        ? ProfileTextAction(
                            label: 'Sahnedeki oyunlara göz at',
                            onTap: () =>
                                NavigationHandler.goToDiscover(context),
                          )
                        : null,
                  ),
          ),
        ),
        if (story.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: 'Hikâye',
            child: ShowStoryBlock(text: story, collapsible: compact),
          ),
        ],
        if (pastShows.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: 'Geçmiş oyunlar',
            meta: '${pastShows.length} oyun',
            child: ProfileArchiveBlock(shows: pastShows),
          ),
        ],
        if (team.photosId.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: 'Fotoğraflar',
            meta: '${team.photosId.length} fotoğraf',
            child: GallerySection(photos: team.photosId),
          ),
        ],
      ],
    );
  }
}
