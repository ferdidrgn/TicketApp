import 'package:ticketapp/core/common/base_state.dart';
import 'package:ticketapp/domain/entities/campaign.dart';

class CampaignState extends BaseState {
  List<Campaign>? campaigns;

  CampaignState({
    List<Campaign>? campaigns,
    super.isLoading = false,
    super.errorMessage,
  }) : campaigns = campaigns ?? [];

  @override
  CampaignState copyWith({
    List<Campaign>? campaigns,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CampaignState(
      campaigns: campaigns ?? this.campaigns,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
