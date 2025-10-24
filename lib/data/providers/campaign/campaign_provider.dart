import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/campaign/get_campaigns_use_case_impl.dart';
import '../../repository/campaign/campaign_repository_provider.dart';
import 'campaign_notifier.dart';
import 'campaign_state.dart';

final campaignProvider = NotifierProvider<CampaignNotifier, CampaignState>(
  CampaignNotifier.new,
);

// GetCampaignsUseCase provider
final getCampaignsUseCaseProvider = Provider<GetCampaignsUseCase>(
  (final ref) => GetCampaignsUseCaseImpl(ref.watch(campaignRepositoryProvider)),
);
