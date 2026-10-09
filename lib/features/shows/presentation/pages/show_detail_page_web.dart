import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../widgets/sahne/show_experience.dart';

/// OYUN DETAYI — WEB. Aynı `ShowExperience`: dar ekranda tek sütun + alt
/// bilet çubuğu, geniş ekranda solda sabit bilet paneli. Kendi `Scaffold`'unu
/// kurar (Material atası olmadan InkWell/TextField çöker).
class ShowDetailPage extends ConsumerWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Scaffold(
        backgroundColor: context.colors.surface,
        body: ShowExperience(
          showId: showId,
          footer: context.isMobile
              ? null
              : const Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: Footer(),
                ),
        ),
      );
}
