import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/campaign/get_campaigns_use_case_impl.dart';
import '../../repository/campaign/campaign_repository_provider.dart';
import 'campaign_notifier.dart';
import 'campaign_state.dart';

final campaignProvider =
    StateNotifierProvider<CampaignNotifier, CampaignState>((ref) {
  return CampaignNotifier(ref.watch(getCampaignsUseCaseProvider));
});

// GetCampaignsUseCase provider
final getCampaignsUseCaseProvider = Provider<GetCampaignsUseCase>((ref) {
  final repository = ref.watch(campaignRepositoryProvider);
  return GetCampaignsUseCaseImpl(repository);
});
