import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Oyun detayı yüklenirken sayfanın kendi şeklinde iskelet (tam sayfa
/// spinner yerine). [twoPane] → masaüstü: solda bilet, sağda program.
class ShowDetailSkeleton extends StatelessWidget {
  final bool twoPane;
  const ShowDetailSkeleton({super.key, required this.twoPane});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final bool reduce = MediaQuery.of(context).disableAnimations;
    final Color base = colors.surfaceContainerHighest;
    final Color highlight = colors.surfaceContainerLow;

    Widget block(final double h,
            {final double? w, final double r = AppRadius.sm}) =>
        Container(
          height: h,
          width: w ?? double.infinity,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(r),
          ),
        );

    final Widget ticket = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block(twoPane ? 300 : 320, r: AppRadius.xl),
        const SizedBox(height: AppSpacing.lg),
        block(34, w: 260, r: AppRadius.md),
        const SizedBox(height: AppSpacing.md),
        block(20, w: 180, r: AppRadius.md),
        const SizedBox(height: AppSpacing.xl),
        block(twoPane ? 88 : 120, r: AppRadius.xl),
      ],
    );

    final Widget programme = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block(28, w: 160),
        const SizedBox(height: AppSpacing.xl),
        for (int i = 0; i < 3; i++) ...[
          block(96, r: AppRadius.md),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xxl),
        block(28, w: 140),
        const SizedBox(height: AppSpacing.xl),
        for (int i = 0; i < 4; i++) ...[
          block(16),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );

    final Widget content = twoPane
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.huge),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 400, child: ticket),
                    const SizedBox(width: AppSpacing.section),
                    Expanded(child: programme),
                  ],
                ),
              ),
            ),
          )
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                    AppSpacing.section, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ticket,
                    const SizedBox(height: AppSpacing.huge),
                    programme,
                  ],
                ),
              ),
            ),
          );

    final Widget scroll = SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: content,
    );

    return Semantics(
      label: 'Oyun bilgileri yükleniyor',
      child: ExcludeSemantics(
        child: reduce
            ? scroll
            : Shimmer.fromColors(
                baseColor: base,
                highlightColor: highlight,
                child: scroll,
              ),
      ),
    );
  }
}

/// Uçan afişin ALTINDA program iskeleti — kapağı yemez, Hero yaşar.
class ShowProgrammeSkeleton extends StatelessWidget {
  const ShowProgrammeSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final bool reduce = MediaQuery.of(context).disableAnimations;
    final Color base = colors.surfaceContainerHighest;
    final Color highlight = colors.surfaceContainerLow;

    Widget block(final double h, {final double? w}) => Container(
          height: h,
          width: w ?? double.infinity,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );

    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.huge, AppSpacing.lg, AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(18, w: 88),
          const SizedBox(height: AppSpacing.sm),
          block(32, w: 220),
          const SizedBox(height: AppSpacing.xl),
          block(108),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (int i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: block(88)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.huge),
          block(18, w: 72),
          const SizedBox(height: AppSpacing.sm),
          block(28, w: 180),
          const SizedBox(height: AppSpacing.xl),
          block(16),
          const SizedBox(height: AppSpacing.sm),
          block(16),
          const SizedBox(height: AppSpacing.sm),
          block(16, w: 240),
        ],
      ),
    );

    return Semantics(
      label: 'Program yükleniyor',
      child: ExcludeSemantics(
        child: reduce
            ? body
            : Shimmer.fromColors(
                baseColor: base,
                highlightColor: highlight,
                child: body,
              ),
      ),
    );
  }
}
