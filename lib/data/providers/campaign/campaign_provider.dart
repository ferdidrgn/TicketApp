import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/useCase/campaign/get_campaigns_use_case_impl.dart';
import '../../repository/campaign/campaign_repository_provider.dart';
import 'campaign_notifier.dart';
import 'campaign_state.dart';

final campaignProvider =
    StateNotifierProvider<CampaignNotifier, CampaignState>((final ref) {
  return CampaignNotifier(ref.read(internetServiceProvider),
      ref.watch(getCampaignsUseCaseProvider));
});

// GetCampaignsUseCase provider
final getCampaignsUseCaseProvider = Provider<GetCampaignsUseCase>((final ref) {
  final repository = ref.watch(campaignRepositoryProvider);
  return GetCampaignsUseCaseImpl(repository);
});
