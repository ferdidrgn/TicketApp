import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../widgets/sahne/show_experience.dart';

/// OYUN DETAYI — MOBİL UYGULAMA (Android/iOS, telefon + tablet).
/// Tüm içerik `ShowExperience` ("Sahne") — web ile aynı duyarlı yüzey.
class ShowDetailPage extends ConsumerWidget {
  final String showId;

  const ShowDetailPage({super.key, required this.showId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (final didPop, final _) {
          if (!didPop) NavigationHandler.smartGoBack(context);
        },
        child: Scaffold(
          backgroundColor: context.colors.surface,
          body: ShowExperience(showId: showId),
        ),
      );
}
