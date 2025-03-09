import '../../../domain/entities/campaign.dart';

class CampaignState {
  final List<Campaign?> campaigns;
  final bool isLoading;
  final String? errorMessage;

  CampaignState({
    this.isLoading = false,
    this.errorMessage,
    final List<Campaign?>? campaigns,
  }) : campaigns = campaigns ?? [];

  CampaignState copyWith({
    final List<Campaign?>? campaigns,
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
