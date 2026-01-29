import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/players/presentation/providers/player_provider.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../domain/entities/show.dart';
import '../../providers/show_provider.dart';

class ShowMosaicGallery extends StatelessWidget {
  final List<Show> shows;
  final bool isLoading;
  final Axis direction;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const ShowMosaicGallery({
    super.key,
    required this.shows,
    this.isLoading = false,
    this.direction = Axis.vertical,
    this.physics,
    this.padding,
  });

  @override
  Widget build(final BuildContext context) {
    if (isLoading)
      return direction == Axis.vertical
          ? _VerticalMosaicShimmer(padding: padding)
          : _HorizontalMosaicShimmer(padding: padding);

    if (shows.isEmpty) return const SizedBox();

    // YATAY MOD (VİTRİN)
    if (direction == Axis.horizontal) {
      return SizedBox(
        height: 340,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          itemCount: (shows.length / 2).ceil(),
          physics: physics ?? const BouncingScrollPhysics(),
          itemBuilder: (final context, final index) {
            final s1 = (index * 2 < shows.length) ? shows[index * 2] : null;
            final s2 =
                (index * 2 + 1 < shows.length) ? shows[index * 2 + 1] : null;

            if (s1 == null) return const SizedBox();

            final flexes = switch (index % 4) {
              0 => (5, 2),
              1 => (3, 4),
              2 => (2, 5),
              _ => (4, 3)
            };

            return Container(
              width: 155,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Expanded(flex: flexes.$1, child: _MosaicCard(show: s1)),
                  const SizedBox(height: 10),
                  if (s2 != null)
                    Expanded(flex: flexes.$2, child: _MosaicCard(show: s2))
                  else
                    Spacer(flex: flexes.$2),
                ],
              ),
            );
          },
        ),
      );
    }

    // DİKEY MOD (LİSTE)
    return SliverPadding(
      padding:
          padding as EdgeInsets? ?? const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (final context, final index) {
            final chunk = index * 3;
            if (chunk >= shows.length) return null;

            final s1 = shows[chunk];
            final s2 = (chunk + 1 < shows.length) ? shows[chunk + 1] : null;
            final s3 = (chunk + 2 < shows.length) ? shows[chunk + 2] : null;

            final isLeftHeavy = index % 2 == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLeftHeavy) ...[
                      _BigItem(show: s1, offset: 10),
                      const SizedBox(width: 12),
                      _SmallColumn(top: s2, bottom: s3),
                    ] else ...[
                      _SmallColumn(top: s1, bottom: s2),
                      const SizedBox(width: 12),
                      s3 != null
                          ? _BigItem(show: s3, offset: -10)
                          : const Spacer(flex: 10),
                    ],
                  ],
                ),
              ),
            );
          },
          childCount: (shows.length / 3).ceil(),
        ),
      ),
    );
  }
}

// =========================================================
// GÜNCELLENEN KISIM: _MosaicCard ARTIK ConsumerWidget
// =========================================================
class _MosaicCard extends ConsumerWidget {
  final Show show;

  const _MosaicCard({required this.show});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      GestureDetector(
        onTap: () async =>
            NavigationHandler.goToShow(context, show.id, show.name),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedCachedImage(imageUrl: show.imageUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85)
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3))),
                      child: const Text("ETKİNLİK",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(show.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// DİĞER YARDIMCI GÖRSELLER AYNI
class _BigItem extends StatelessWidget {
  final Show show;
  final double offset;

  const _BigItem({required this.show, required this.offset});

  @override
  Widget build(final BuildContext context) => Expanded(
      flex: 10,
      child: Transform.translate(
        offset: Offset(0, offset),
        child: SizedBox(height: 320, child: _MosaicCard(show: show)),
      ));
}

class _SmallColumn extends StatelessWidget {
  final Show? top;
  final Show? bottom;

  const _SmallColumn({required this.top, this.bottom});

  @override
  Widget build(final BuildContext context) => Expanded(
      flex: 9,
      child: Column(
        children: [
          if (top != null)
            SizedBox(height: 150, child: _MosaicCard(show: top!)),
          if (bottom != null) ...[
            const SizedBox(height: 12),
            SizedBox(height: 150, child: _MosaicCard(show: bottom!))
          ],
        ],
      ));
}

// SHIMMER WIDGETLARI
class _HorizontalMosaicShimmer extends StatelessWidget {
  final EdgeInsetsGeometry? padding;

  const _HorizontalMosaicShimmer({this.padding});

  @override
  Widget build(final BuildContext context) => SizedBox(
      height: 340,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (final _, final i) {
          final f = switch (i % 4) {
            0 => (5, 2),
            1 => (3, 4),
            2 => (2, 5),
            _ => (4, 3)
          };
          return Container(
            width: 155,
            margin: const EdgeInsets.only(right: 10),
            child: Column(children: [
              Expanded(
                  flex: f.$1,
                  child: const ShimmerLoading(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 16)),
              const SizedBox(height: 10),
              Expanded(
                  flex: f.$2,
                  child: const ShimmerLoading(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 16))
            ]),
          );
        },
      ));
}

class _VerticalMosaicShimmer extends StatelessWidget {
  final EdgeInsetsGeometry? padding;

  const _VerticalMosaicShimmer({this.padding});

  @override
  Widget build(final BuildContext context) => SliverPadding(
      padding:
          padding as EdgeInsets? ?? const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (final _, final index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: ShimmerLoading(
                        width: double.infinity,
                        height: 200 + (index % 2) * 80,
                        borderRadius: 20)),
                const SizedBox(width: 12),
                Expanded(
                    child: ShimmerLoading(
                        width: double.infinity,
                        height: 280 - (index % 2) * 80,
                        borderRadius: 20)),
              ],
            ),
          ),
          childCount: 4,
        ),
      ));
}
