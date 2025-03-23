import '../../model/campaing_model.dart';

class CampaignState {
  final List<CampaignModel?> campaigns;
  final bool isLoading;
  final String? errorMessage;

  CampaignState({
    this.isLoading = false,
    this.errorMessage,
    final List<CampaignModel?>? campaigns,
  }) : campaigns = campaigns ?? [];

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
