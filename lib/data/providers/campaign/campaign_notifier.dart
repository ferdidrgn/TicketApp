import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'campaign_provider.dart';
import 'campaign_state.dart';

class CampaignNotifier extends BaseNotifierWithNetworkChecker<CampaignState> {
  @override
  CampaignState initialState() => const CampaignState();

  @override
  void reloadData() => loadCampaigns();

  Future<void> loadCampaigns() => executeWithInternetCheck(
        () => ref.read(getCampaignsUseCaseProvider).call(),
        onSuccess: (final campaigns) =>
            state = state.copyWith(dataList: campaigns),
      );
}
