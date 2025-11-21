import 'package:ticketapp/core/common/base_notifier.dart';
import 'campaign_provider.dart';
import 'campaign_state.dart';

class CampaignNotifier extends BaseNotifier<CampaignState> {
  @override
  CampaignState initialState() => const CampaignState();

  Future<void> loadCampaigns() => execute(
      () => ref.read(getCampaignsUseCaseProvider).call(),
      onSuccess: (final campaigns) => state = state.copyWith(dataList: campaigns));
}
