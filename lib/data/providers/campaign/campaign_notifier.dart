import 'package:ticketapp/core/common/base_notifier_with_base_state.dart';

import '../../../domain/useCase/campaign/get_campaigns_use_case_impl.dart';
import 'campaign_state.dart';

class CampaignNotifier extends BaseNotifierWithBaseState<CampaignState> {
  final GetCampaignsUseCase getCampaignsUseCase;

  CampaignNotifier(this.getCampaignsUseCase) : super(CampaignState());

  Future<void> loadCampaigns() async {
    await handleOperation(
      () => getCampaignsUseCase.call(),
      onSuccess: (final campaigns) =>
          state = state.copyWith(dataList: campaigns),
    );
  }
}
