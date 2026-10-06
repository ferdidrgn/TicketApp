import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/gallery_section.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../../shared/widgets/theatre_show_card.dart';
import '../../../../players/domain/entities/player.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../domain/entities/show.dart';
import '../../providers/show_provider.dart';
import 'show_detail_data.dart';
import 'show_session_ticket.dart';

/// Tiyatro programı (broşür) gibi okunan sakin bölümler: seanslar, hikâye,
/// oyuncular, sahne, galeri, benzer oyunlar. Kart yığını yok; bölümler
/// Playfair başlık + ince çizgiyle ayrılır, metin okuma genişliğinde kalır.
class ShowProgramme extends StatelessWidget {
  final ShowDetailData data;
  final GlobalKey sessionsKey;
  final void Function(ShowSession session) onSelectSession;

  /// Mobil (dar) düzen: kadro yatay şerit, hikâye katlanır, küçük kartlar.
  final bool compact;

  const ShowProgramme({
    super.key,
    required this.data,
    required this.sessionsKey,
    required this.onSelectSession,
    required this.compact,
  });

  @override
  Widget build(final BuildContext context) {
    final double gap = compact ? AppSpacing.huge : AppSpacing.section;
    final String story = data.description;
    final show = data.show;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: sessionsKey,
          child: ProgrammeSection(
            title: 'Seanslar',
            meta: data.isExternal || data.sessions.isEmpty
                ? null
                : '${data.sessions.length} seans',
            child: ShowSessionsBlock(
              data: data,
              onSelect: onSelectSession,
              compact: compact,
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
        if (data.cast.isNotEmpty || data.pastCast.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: 'Oyuncular',
            child: ShowCastBlock(
              cast: data.cast,
              pastCast: data.pastCast,
              compact: compact,
            ),
          ),
        ],
        if (data.venues.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: data.venues.length > 1 ? 'Sahneler' : 'Sahne',
            child: ShowVenueBlock(venues: data.venues),
          ),
        ],
        if (show.photosShowId.isNotEmpty) ...[
          SizedBox(height: gap),
          ProgrammeSection(
            title: 'Sahneden',
            meta: '${show.photosShowId.length} fotoğraf',
            child: GallerySection(photos: show.photosShowId),
          ),
        ],
        ShowSimilarStrip(
          currentShow: show,
          topGap: gap,
          cardWidth: compact ? 168 : 210,
          height: compact ? 292 : 340,
        ),
      ],
    );
  }
}

/// Bölüm başlığı: Playfair başlık, isteğe bağlı gerçek sayı (ör. "4
/// seans"), altında ince çizgi.
class ProgrammeSection extends StatelessWidget {
  final String title;
  final String? meta;
  final Widget child;

  const ProgrammeSection({
    super.key,
    required this.title,
    required this.child,
    this.meta,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: colors.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              if (meta != null) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  meta!,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const TicketInkHairline(strong: 0.38, soft: 0.22),
        const SizedBox(height: AppSpacing.xl),
        child,
      ],
    );
  }
}

/// Seans listesi. Harici satışta açıklama, seans yoksa boş durum; varsa
/// `Show.eventRule` notu + yırtılabilir seans koçanları (ilk 6, gerisi
/// "Tüm seansları göster" ile).
class ShowSessionsBlock extends StatefulWidget {
  final ShowDetailData data;
  final void Function(ShowSession session) onSelect;
  final bool compact;

  const ShowSessionsBlock({
    super.key,
    required this.data,
    required this.onSelect,
    required this.compact,
  });

  @override
  State<ShowSessionsBlock> createState() => _ShowSessionsBlockState();
}

class _ShowSessionsBlockState extends State<ShowSessionsBlock> {
  static const int _initialCount = 6;
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final data = widget.data;
    final TextStyle? body = context.textTheme.bodyLarge
        ?.copyWith(color: colors.onSurfaceVariant, height: 1.5);

    if (data.isExternal) {
      return Text(
        'Bu oyunun seans takvimi ve biletleri, satışın yapıldığı '
        'platformda. Bilet butonu seni doğrudan o sayfaya götürür.',
        style: body,
      );
    }

    if (data.sessions.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_busy_rounded, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Şu an satışta seans yok. Yeni seanslar eklendiğinde burada '
              'görünecek.',
              style: body,
            ),
          ),
        ],
      );
    }

    // `eventRule` Firebase'den gelen serbest metin; "yok", "-" gibi yer
    // tutucular not olarak gösterilmez.
    final String rawRule = data.show.eventRule.trim();
    final String rule =
        const {'yok', '-', '—', 'none', 'null'}.contains(rawRule.toLowerCase())
            ? ''
            : rawRule;
    final int total = data.sessions.length;
    final int visible =
        _expanded ? total : (total < _initialCount ? total : _initialCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rule.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.info_outline_rounded,
                    size: 16, color: colors.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  rule,
                  style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant, height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        for (int i = 0; i < visible; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          ShowSessionTicket(
            key: ValueKey(data.sessions[i].event.id),
            session: data.sessions[i],
            compact: widget.compact,
            onSelect: () => widget.onSelect(data.sessions[i]),
          ),
        ],
        if (total > _initialCount) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: colors.primary,
              ),
              icon: Icon(_expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded),
              label: Text(_expanded
                  ? 'Daha az göster'
                  : 'Tüm seansları göster ($total)'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Hikâye metni. Web'de seçilebilir ve tam; mobilde uzunsa katlanır.
class ShowStoryBlock extends StatefulWidget {
  final String text;
  final bool collapsible;

  const ShowStoryBlock(
      {super.key, required this.text, required this.collapsible});

  @override
  State<ShowStoryBlock> createState() => _ShowStoryBlockState();
}

class _ShowStoryBlockState extends State<ShowStoryBlock> {
  static const int _collapsedLines = 7;
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final TextStyle style = (context.textTheme.bodyLarge ?? const TextStyle())
        .copyWith(
            color: colors.onSurface.withOpacity(0.86),
            fontSize: widget.collapsible ? 16 : 17,
            height: 1.6);

    if (!widget.collapsible) return SelectableText(widget.text, style: style);

    final bool long = widget.text.length > 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            style: style,
            maxLines: long && !_expanded ? _collapsedLines : null,
            overflow: long && !_expanded ? TextOverflow.fade : null,
          ),
        ),
        if (long)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              foregroundColor: colors.primary,
            ),
            child: Text(_expanded ? 'Daha az göster' : 'Devamını oku'),
          ),
      ],
    );
  }
}

/// Oyuncular — programdaki kadro listesi gibi: portre + ad. Önceki kadro
/// soluk ve küçük. Her isim oyuncu sayfasına gider.
class ShowCastBlock extends StatelessWidget {
  final List<Player> cast;
  final List<Player> pastCast;
  final bool compact;

  const ShowCastBlock({
    super.key,
    required this.cast,
    required this.pastCast,
    required this.compact,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final Widget? current = cast.isEmpty
        ? null
        : compact
            ? SizedBox(
                height: 136,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cast.length,
                  separatorBuilder: (final _, final __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (final context, final i) =>
                      _CastPortrait(player: cast[i]),
                ),
              )
            : Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.md,
                children: [
                  for (final p in cast) _CastRow(player: p, past: false),
                ],
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (current != null) current,
        if (pastCast.isNotEmpty) ...[
          if (current != null) const SizedBox(height: AppSpacing.xl),
          Text(
            'Önceki kadro',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              for (final p in pastCast) _CastRow(player: p, past: true),
            ],
          ),
        ],
      ],
    );
  }
}

String _fullName(final Player p) => '${p.firstName} ${p.lastName}'.trim();

const ColorFilter _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

class _Avatar extends StatelessWidget {
  final Player player;
  final double size;
  final bool past;

  const _Avatar({required this.player, required this.size, this.past = false});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final Widget image = player.imageUrl.trim().isEmpty
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded,
                size: size * 0.5, color: colors.onSurfaceVariant),
          )
        : ClipOval(
            child: OptimizedCachedImage(
              imageUrl: player.imageUrl,
              width: size,
              height: size,
              isCircular: true,
              fit: BoxFit.cover,
            ),
          );
    return past ? ColorFiltered(colorFilter: _grayscale, child: image) : image;
  }
}

class _CastPortrait extends StatelessWidget {
  final Player player;
  const _CastPortrait({required this.player});

  @override
  Widget build(final BuildContext context) {
    final String name = _fullName(player);
    return Semantics(
      button: true,
      label: '$name, oyuncu sayfasını aç',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => NavigationHandler.goToPlayer(context, player.id, name),
        child: SizedBox(
          width: 92,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                _Avatar(player: player, size: 72),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CastRow extends StatelessWidget {
  final Player player;
  final bool past;

  const _CastRow({required this.player, required this.past});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final String name = _fullName(player);
    return Semantics(
      button: true,
      label: '$name${past ? ', önceki kadro' : ''}, oyuncu sayfasını aç',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => NavigationHandler.goToPlayer(context, player.id, name),
        child: SizedBox(
          width: past ? 190 : 210,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: AppSpacing.xs + 2),
            child: Row(
              children: [
                _Avatar(player: player, size: past ? 36 : 48, past: past),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: (past
                            ? context.textTheme.bodyMedium
                            : context.textTheme.titleSmall)
                        ?.copyWith(
                      color: past ? colors.onSurfaceVariant : colors.onSurface,
                      fontWeight: past ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seansların oynandığı sahneler — ad + adres, sahne sayfasına gider.
class ShowVenueBlock extends StatelessWidget {
  final List<Stage> venues;
  const ShowVenueBlock({super.key, required this.venues});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < venues.length; i++) ...[
          if (i > 0)
            Divider(height: 1, color: colors.outlineVariant.withOpacity(0.5)),
          _VenueRow(stage: venues[i]),
        ],
      ],
    );
  }
}

class _VenueRow extends StatelessWidget {
  final Stage stage;
  const _VenueRow({required this.stage});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final String address = stage.address.trim();
    return Semantics(
      button: true,
      label: '${stage.name}${address.isEmpty ? '' : ', $address'}, '
          'sahne sayfasını aç',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => NavigationHandler.goToStage(context, stage.id, stage.name),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.place_outlined, color: colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stage.name,
                        style: GoogleFonts.playfairDisplay(
                          color: colors.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          address,
                          style: context.textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Benzer oyunlar" — aynı kategorideki (`Show.category`) diğer oyunlar,
/// paylaşılan bilet-koçanı `TheatreShowCard` ile. Kategori boşsa ya da
/// başka oyun yoksa (başlığıyla birlikte) hiç çizilmez.
class ShowSimilarStrip extends ConsumerStatefulWidget {
  final Show currentShow;
  final double topGap;
  final double cardWidth;
  final double height;

  const ShowSimilarStrip({
    super.key,
    required this.currentShow,
    required this.topGap,
    required this.cardWidth,
    required this.height,
  });

  @override
  ConsumerState<ShowSimilarStrip> createState() => _ShowSimilarStripState();
}

class _ShowSimilarStripState extends ConsumerState<ShowSimilarStrip> {
  // Fare tekerleği (dikey delta) yatay kaydırmaya çevriliyor — web'de
  // tekerlekle kaydırılabilsin.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final showsAsync = ref.watch(showsActiveFirstProvider(true));
    final List<Show> all = showsAsync.value ?? const <Show>[];
    final String category = widget.currentShow.category.trim();
    if (category.isEmpty) return const SizedBox.shrink();
    final similar = all
        .where((final s) =>
            s.id != widget.currentShow.id && s.category.trim() == category)
        .take(10)
        .toList();
    if (similar.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: widget.topGap),
      child: ProgrammeSection(
        title: 'Benzer oyunlar',
        child: SizedBox(
          height: widget.height,
          child: Listener(
            onPointerSignal: (final event) {
              if (event is! PointerScrollEvent ||
                  !_scrollController.hasClients) {
                return;
              }
              final double target =
                  (_scrollController.offset + event.scrollDelta.dy).clamp(
                _scrollController.position.minScrollExtent,
                _scrollController.position.maxScrollExtent,
              );
              _scrollController.jumpTo(target);
            },
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                // Kartların kalkma/gölge efekti kırpılmasın.
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                clipBehavior: Clip.none,
                itemCount: similar.length,
                separatorBuilder: (final _, final __) =>
                    const SizedBox(width: AppSpacing.lg),
                itemBuilder: (final context, final index) {
                  final show = similar[index];
                  return SizedBox(
                    width: widget.cardWidth,
                    child: TheatreShowCard(
                      show: show,
                      onTap: () =>
                          NavigationHandler.goToShow(context, show.id, show.name),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
