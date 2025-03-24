import 'package:ticketapp/core/common/base_state.dart';

import '../../model/campaing_model.dart';

class CampaignState extends BaseState {
  final List<CampaignModel?> campaigns;

  CampaignState({
    super.isLoading = false,
    super.errorMessage,
    final List<CampaignModel?>? campaigns,
  }) : campaigns = campaigns ?? [];

  @override
  CampaignState copyWith({
    final List<CampaignModel?>? campaigns,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return CampaignState(
      campaigns: campaigns ?? this.campaigns,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
