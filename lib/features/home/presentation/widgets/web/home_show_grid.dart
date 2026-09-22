import 'package:flutter/material.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../../shared/widgets/theatre_show_card.dart';

/// "Sahnede Bu Sezon" repertuar ızgarası.
///
/// Gerçek bir bilet platformunun repertuar/keşif sayfasında göreceğin türden
/// sakin, kart tabanlı bir ızgara — mobildeki collage'ın bire bir kopyası
/// değil, masaüstüne özel sıfırdan bir kompozisyon.
class HomeShowGrid extends StatelessWidget {
  final List<Show> shows;
  final void Function(Show show) onShowTap;

  const HomeShowGrid({
    super.key,
    required this.shows,
    required this.onShowTap,
  });

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1280
              ? 4
              : width >= 900
                  ? 3
                  : width >= 600
                      ? 2
                      : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shows.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (final context, final index) => TheatreShowCard(
                  show: shows[index],
                  onTap: () => onShowTap(shows[index]),
                ),
          );
        },
      );
}
