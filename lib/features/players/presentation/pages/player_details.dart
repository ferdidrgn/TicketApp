import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/theme/app_radius.dart';
import 'package:ticketapp/core/theme/app_spacing.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/core/util/responsive_utils.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_profile.dart';
import '../../../../shared/widgets/ticket/stage_entrance.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/detail/show_detail_skeleton.dart';
import '../../../shows/presentation/widgets/detail/show_programme.dart';
import '../../domain/entities/player.dart';
import '../providers/player_provider.dart';

/// OYUNCU SAYFASI — tiyatro programındaki "oyuncu künyesi".
///
/// Kimlik bir künye biletidir (portre, ad, oyuncunun kendi sözü); koçanda
/// TEK birincil aksiyon: şu an sahnedeki oyununa git (tek oyun) ya da
/// sahnedeki oyunlarına in (birden çok). Program: Sahnede (bilet
/// kartları) → Hakkında → Geçmiş oyunlar → Ödüller ve başarılar →
/// Birlikte çalıştıkları. Uydurma istatistik/rozet yok; sadece `Player`
/// ve bağlı `Show` kayıtlarındaki gerçek alanlar.
///
/// Web + mobil aynı dosya; kompozisyonu genişlik belirler (bkz.
/// `ProfileDetailLayout`): masaüstünde yapışkan künye + kayan program,
/// tablette yatay bilet, mobilde tek sütun.
class PlayerDetailPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage>
    with GlobalScrollMixin {
  // `scrollController` GlobalScrollMixin'den gelir ve orada dispose edilir.
  // (Eskiden burada İKİNCİ kez dispose ediliyordu.)
  final GlobalKey _onStageKey = GlobalKey();

  @override
  Widget build(final BuildContext context) {
    final playerAsync = ref.watch(playerDetailProvider(widget.playerId));
    final bool twoPane =
        MediaQuery.sizeOf(context).width >= ResponsiveUtils.tabletBreakpoint;

    return ProfilePageShell(
      child: playerAsync.when(
        loading: () => ShowDetailSkeleton(twoPane: twoPane),
        error: (final err, final _) => ProfileErrorView(
          error: err,
          notFoundTitle: 'Bu oyuncu bulunamadı',
          failedTitle: 'Oyuncu bilgileri yüklenemedi',
          onRetry: () =>
              ref.invalidate(playerDetailProvider(widget.playerId)),
        ),
        data: (final state) => _buildPage(context, state),
      ),
    );
  }

  Widget _buildPage(final BuildContext context, final PlayerDetailState state) {
    final Player player = state.player;
    final String fullName =
        '${player.firstName} ${player.lastName}'.trim();

    // `nowShowsId` elle tutulan bir liste; canlı takvimle çapraz kontrol
    // edilir (eskiden sadece masaüstünde yapılıyordu ve aktif olmayanlar
    // sayfadan tamamen kayboluyordu — artık "Geçmiş oyunlar"a iner).
    final split = splitShowsByLiveActivity(
      claimedActive: state.activeShows,
      past: state.pastShows,
      liveActive: ref.watch(activeShowsProvider(false)).value,
    );

    return StageEntrance(
      imageUrl: player.imageUrl,
      label: fullName,
      portrait: true,
      child: ProfileDetailLayout(
      controller: scrollController,
      footer: kIsWeb ? const Footer() : null,
      heroImageUrl: player.imageUrl,
      heroImageLabel: '$fullName portresi',
      heroPortrait: true,
      heroPlaceholderIcon: Icons.person_rounded,
      heroTag: 'player_${player.id}',
      actions: ({final bool onPhoto = false}) => ProfileActionsRow(
        onPhoto: onPhoto,
        shareLabel: 'Oyuncu profilini paylaş',
        onShare: () =>
            TiyatrolDeeplinkService.shareActor(id: player.id, name: fullName),
      ),
      ticket: (final layout, {final bool heroPhoto = false}) => ProfileTicket(
        layout: layout,
        kind: 'OYUNCU',
        name: fullName,
        imageUrl: player.imageUrl,
        imageLabel: '$fullName portresi',
        portrait: true,
        omitBodyPhoto: heroPhoto,
        photoHeroTag: heroPhoto ? null : 'player_${player.id}',
        placeholderIcon: Icons.person_rounded,
        tagline: player.quote,
        taglineIsQuote: true,
        seed: player.id,
        stubFields: [
          TicketField(
            label: 'ŞU AN SAHNEDE',
            value: switch (split.active.length) {
              0 => 'Sahnede oyunu yok',
              1 => split.active.first.name,
              _ => '${split.active.length} oyunda',
            },
          ),
        ],
        action: _primaryAction(context, split.active),
      ),
      programme: (final compact) => _Programme(
        player: player,
        activeShows: split.active,
        pastShows: split.past,
        compact: compact,
        onStageKey: _onStageKey,
      ),
    ),
    );
  }

  /// Sayfanın TEK birincil aksiyonu. Sahnede oyunu yoksa aksiyon yok
  /// (koçanda barkod basılır).
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
  final Player player;
  final List<Show> activeShows;
  final List<Show> pastShows;
  final bool compact;
  final GlobalKey onStageKey;

  const _Programme({
    required this.player,
    required this.activeShows,
    required this.pastShows,
    required this.compact,
    required this.onStageKey,
  });

  @override
  Widget build(final BuildContext context) {
    final double gap = compact ? AppSpacing.huge : AppSpacing.section;
    final String bio = player.bio.trim();
    final achievements = player.achievements
        .where((final a) =>
            (a['title'] ?? '').trim().isNotEmpty ||
            (a['year'] ?? '').trim().isNotEmpty)
        .toList();
    final collaborations = player.collaborations
        .map((final c) => c.trim())
        .where((final c) => c.isNotEmpty)
        .toList();
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
                        ? 'Şu an sahnede bir oyunu yok.'
                        : 'Şu an sahnede bir oyunu yok. Rol aldığı oyunlar '
                            'aşağıda.',
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
        if (bio.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: 'Hakkında',
            child: ShowStoryBlock(text: bio, collapsible: compact),
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
        if (achievements.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: 'Ödüller ve başarılar',
            child: _AchievementList(items: achievements),
          ),
        ],
        if (collaborations.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: 'Birlikte çalıştıkları',
            child: _CreditList(names: collaborations),
          ),
        ],
      ],
    );
  }
}

/// Program kitapçığındaki gibi yıl + başlık satırları (zaman çizelgesi
/// noktaları/`IntrinsicHeight` yok).
class _AchievementList extends StatelessWidget {
  final List<Map<String, String>> items;
  const _AchievementList({required this.items});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0)
            Divider(height: 1, color: colors.outlineVariant.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    (items[i]['year'] ?? '').trim(),
                    style: GoogleFonts.playfairDisplay(
                      color: colors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (items[i]['title'] ?? '').trim(),
                        style: context.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      if ((items[i]['detail'] ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          items[i]['detail']!.trim(),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Birlikte çalıştığı isimler — sade, çerçeveli etiketler (gölge yok).
class _CreditList extends StatelessWidget {
  final List<String> names;
  const _CreditList({required this.names});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final name in names)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Text(
              name,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
