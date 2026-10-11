import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../widgets/sahne/team_experience.dart';

/// TOPLULUK SAYFASI — telefon, tablet ve web için `TeamExperience` ("Sahne").
///
/// Dosya adı tarihsel: router web ve mobilde bu tek sayfayı kullanır.
class TeamDetailsPage extends ConsumerWidget {
  final String teamId;

  const TeamDetailsPage({super.key, required this.teamId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (final didPop, final _) {
          if (!didPop) {
            NavigationHandler.smartGoBack(context);
          }
        },
        child: Scaffold(
          backgroundColor: context.colors.surface,
          body: TeamExperience(
            teamId: teamId,
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
