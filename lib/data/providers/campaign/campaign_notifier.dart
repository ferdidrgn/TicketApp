import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';

import '../../../core/network/internet_service.dart';
import '../../../domain/useCase/campaign/get_campaigns_use_case_impl.dart';
import 'campaign_state.dart';

class CampaignNotifier extends BaseNotifierWithNetworkChecker<CampaignState> {
  final GetCampaignsUseCase getCampaignsUseCase;

  CampaignNotifier(
      final InternetService internetService, this.getCampaignsUseCase)
      : super(internetService, CampaignState());

  @override
  void reloadData() => loadCampaigns();

  Future<void> loadCampaigns() => executeWithInternetCheck(
        () => getCampaignsUseCase.call(),
        onSuccess: (final campaigns) =>
            state = state.copyWith(dataList: campaigns),
      );
}
