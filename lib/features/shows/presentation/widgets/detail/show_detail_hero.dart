import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import '../show_team_credit.dart';
import 'show_detail_data.dart';

/// Oyun detayının sinematik / editoryal kahramanı — TodayTix tarzı afiş +
/// başlık; bilet kağıdı ve koçan değil. Bilet dili yalnızca birincil
/// aksiyonda (`ShowPrimaryStamp`).
enum ShowDetailHeroLayout { stacked, aside, banner }

class ShowDetailHero extends StatelessWidget {
  final ShowDetailData data;
  final ShowDetailHeroLayout layout;
  final Animation<double> headlineReveal;
  final Animation<double> detailsFade;
  final double posterHeight;

  /// Masaüstü / tablet: kahramanın altında veya yanında tek birincil aksiyon.
  final Widget? primaryAction;

  const ShowDetailHero({
    super.key,
    required this.data,
    required this.layout,
    required this.headlineReveal,
    required this.detailsFade,
    this.posterHeight = 280,
    this.primaryAction,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.level2(colors.shadow),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: _HeroBody(
          data: data,
          layout: layout,
          headlineReveal: headlineReveal,
          detailsFade: detailsFade,
          posterHeight: posterHeight,
          primaryAction: primaryAction,
        ),
      ),
    );
  }
}

class _HeroBody extends StatelessWidget {
  final ShowDetailData data;
  final ShowDetailHeroLayout layout;
  final Animation<double> headlineReveal;
  final Animation<double> detailsFade;
  final double posterHeight;
  final Widget? primaryAction;

  const _HeroBody({
    required this.data,
    required this.layout,
    required this.headlineReveal,
    required this.detailsFade,
    required this.posterHeight,
    this.primaryAction,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final show = data.show;
    final bool hasPoster = show.imageUrl.trim().isNotEmpty;

    final double headlineSize = switch (layout) {
      ShowDetailHeroLayout.stacked => 30.0,
      ShowDetailHeroLayout.aside => 32.0,
      ShowDetailHeroLayout.banner => 34.0,
    };

    final Widget headline = Semantics(
      header: true,
      child: AuthWipeReveal(
        reveal: headlineReveal,
        child: Text(
          show.name,
          style: GoogleFonts.playfairDisplay(
            color: colors.onSurface,
            fontSize: headlineSize,
            fontWeight: FontWeight.w800,
            height: 1.08,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );

    final Widget credit = FadeTransition(
      opacity: detailsFade,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ShowTeamCredit(teamId: show.teamId, onPaper: false),
      ),
    );

    final Widget meta = FadeTransition(
      opacity: detailsFade,
      child: ShowDetailMetaRow(data: data),
    );

    final Widget teaser = FadeTransition(
      opacity: detailsFade,
      child: ShowDetailSessionTeaser(data: data, dense: layout == ShowDetailHeroLayout.aside),
    );

    final Widget kind = FadeTransition(
      opacity: detailsFade,
      child: _KindChip(label: data.kindLabel),
    );

    switch (layout) {
      case ShowDetailHeroLayout.stacked:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              kind,
              const SizedBox(height: AppSpacing.lg),
              headline,
              const SizedBox(height: AppSpacing.md),
              credit,
              const SizedBox(height: AppSpacing.lg),
              meta,
              if (!data.isExternal && data.sessions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                teaser,
              ],
            ],
          ),
        );

      case ShowDetailHeroLayout.aside:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPoster) ...[
                _HeroPoster(
                  url: show.imageUrl,
                  name: show.name,
                  height: posterHeight,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              kind,
              const SizedBox(height: AppSpacing.md),
              headline,
              const SizedBox(height: AppSpacing.md),
              credit,
              const SizedBox(height: AppSpacing.lg),
              meta,
              if (!data.isExternal) ...[
                const SizedBox(height: AppSpacing.lg),
                teaser,
              ] else ...[
                const SizedBox(height: AppSpacing.lg),
                const ShowExternalNoteEditorial(),
              ],
              if (primaryAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                primaryAction!,
              ],
            ],
          ),
        );

      case ShowDetailHeroLayout.banner:
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 280),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                kind,
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPoster) ...[
                      SizedBox(
                        width: 148,
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: _HeroPoster(url: show.imageUrl, name: show.name),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          headline,
                          const SizedBox(height: AppSpacing.md),
                          credit,
                          const SizedBox(height: AppSpacing.lg),
                          meta,
                        ],
                      ),
                    ),
                  ],
                ),
                if (!data.isExternal && data.sessions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  teaser,
                ] else if (data.isExternal) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const ShowExternalNoteEditorial(),
                ],
                if (primaryAction != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  primaryAction!,
                ],
              ],
            ),
          ),
        );
    }
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  const _KindChip({required this.label});

  @override
  Widget build(final BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withOpacity(0.55),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          label.trim().toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _HeroPoster extends StatelessWidget {
  final String url;
  final String name;
  final double? height;

  const _HeroPoster({required this.url, required this.name, this.height});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Semantics(
      image: true,
      label: '$name afişi',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ColoredBox(
          color: colors.surfaceContainerHighest,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: OptimizedCachedImage(
              imageUrl: url,
              fit: BoxFit.cover,
              borderRadius: 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Süre / yaş / tür — tema renklerinde küçük etiketler (bilet alanı değil).
class ShowDetailMetaRow extends StatelessWidget {
  final ShowDetailData data;
  const ShowDetailMetaRow({super.key, required this.data});

  @override
  Widget build(final BuildContext context) {
    final show = data.show;
    final items = <String>[
      if (show.duration.trim().isNotEmpty) show.duration.trim(),
      if (show.ageLimit.trim().isNotEmpty) show.ageLimit.trim(),
      if (data.typeField.isNotEmpty) data.typeField,
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in items)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: colors.outlineVariant.withOpacity(0.45)),
            ),
            child: Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// En yakın seans + fiyat — editoryal özet (koçan / barkod yok).
class ShowDetailSessionTeaser extends StatelessWidget {
  final ShowDetailData data;
  final bool dense;

  const ShowDetailSessionTeaser({
    super.key,
    required this.data,
    this.dense = false,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    if (data.isExternal) return const SizedBox.shrink();

    final ShowSession? next = data.nextSession;
    final double? lowest = data.lowestPrice;
    final bool manyPrices = data.sessions
            .map((final s) => s.price)
            .whereType<double>()
            .toSet()
            .length >
        1;

    if (next == null && lowest == null) {
      return Text(
        'Şu an satışta seans yok',
        style: context.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    final TextStyle label = context.textTheme.labelMedium!.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final TextStyle value = context.textTheme.titleMedium!.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w700,
    );

    if (dense) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (next != null) ...[
            Text('En yakın seans', style: label),
            const SizedBox(height: 2),
            Text(next.shortLabel, style: value),
          ],
          if (lowest != null) ...[
            if (next != null) const SizedBox(height: AppSpacing.md),
            Text(manyPrices ? 'En uygun fiyat' : 'Fiyat', style: label),
            const SizedBox(height: 2),
            Text(formatTicketPrice(lowest), style: value),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (next != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('En yakın seans', style: label),
                const SizedBox(height: 2),
                Text(next.shortLabel, style: value),
              ],
            ),
          ),
        if (lowest != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(manyPrices ? 'En uygun fiyat' : 'Fiyat', style: label),
                const SizedBox(height: 2),
                Text(formatTicketPrice(lowest), style: value),
              ],
            ),
          ),
      ],
    );
  }
}

/// Harici satış — bilet kağıdı stili yerine kısa editoryal not.
class ShowExternalNoteEditorial extends StatelessWidget {
  const ShowExternalNoteEditorial({super.key});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.open_in_new_rounded, size: 18, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Biletler başka bir platformda satılıyor.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
