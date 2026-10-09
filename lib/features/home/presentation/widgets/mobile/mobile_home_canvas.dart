import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/base/base_page_wrapper.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../../players/presentation/providers/player_provider.dart';
import '../../../../stages/presentation/providers/stage_provider.dart';
import '../../../../teams/presentation/providers/team_provider.dart';
import '../../providers/home_sessions_provider.dart';
import '../../providers/home_show_filter_provider.dart';
import '../sahne/home_experience.dart';

/// Telefon/tablet ana sayfası: alt menü + çek-yenile sağlayan
/// `BasePageWrapper` içinde "Sahne" ana sayfası (`HomeExperience`).
class MobileHomeCanvas extends ConsumerStatefulWidget {
  const MobileHomeCanvas({super.key});

  @override
  ConsumerState<MobileHomeCanvas> createState() => _MobileHomeCanvasState();
}

class _MobileHomeCanvasState extends ConsumerState<MobileHomeCanvas> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(campaignsProvider);
    ref.invalidate(homeShowsActiveFirstProvider(true));
    ref.invalidate(homeActiveShowsProvider(true));
    ref.invalidate(stagesProvider(isLimit: true));
    ref.invalidate(homeUpcomingSessionsProvider);
    ref.invalidate(playersProvider());
    ref.invalidate(teamsProvider(isLimit: true));
  }

  @override
  Widget build(final BuildContext context) => BasePageWrapper(
        showBackButton: false,
        showFab: true,
        customScrollController: _scrollController,
        onRefresh: _refresh,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface,
          ambientColor: Colors.transparent,
          extendBody: true,
          safeAreaTop: false,
        ),
        child: HomeExperience(controller: _scrollController),
      );
}
