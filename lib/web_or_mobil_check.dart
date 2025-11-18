import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/navigation/bottom_nav_bar.dart';
import 'package:ticketapp/presentation/web/navigation/web_tab_navigation.dart';
import 'core/util/platform_checker.dart';

class WebOrMobilCheck extends ConsumerWidget {
  const WebOrMobilCheck({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (PlatformChecker.isWeb)
      return const WebTabNavigation();
    else // Mobil ise
      return const BottomNavBar();
  }
}
