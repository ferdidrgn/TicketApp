import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../widgets/sahne/player_experience.dart';

/// OYUNCU SAYFASI — telefon, tablet ve web için `PlayerExperience` ("Sahne").
class PlayerDetailPage extends ConsumerWidget {
  final String playerId;

  const PlayerDetailPage({super.key, required this.playerId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (final didPop, final _) {
          if (!didPop) NavigationHandler.smartGoBack(context);
        },
        child: Scaffold(
          backgroundColor: context.colors.surface,
          body: PlayerExperience(
            playerId: playerId,
            footer: kIsWeb && !context.isMobile
                ? const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Footer(),
                  )
                : null,
          ),
        ),
      );
}
