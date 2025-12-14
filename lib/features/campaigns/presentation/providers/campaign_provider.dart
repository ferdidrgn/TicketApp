import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/campaign_repository_provider.dart';
import '../../domain/usecases/get_campaigns_use_case_impl.dart';
import 'campaign_notifier.dart';
import 'campaign_state.dart';

final campaignProvider =
    NotifierProvider.autoDispose<CampaignNotifier, CampaignState>(
  CampaignNotifier.new,
);

// GetCampaignsUseCase provider
final getCampaignsUseCaseProvider = Provider<GetCampaignsUseCase>((final ref) =>
    GetCampaignsUseCaseImpl(ref.watch(campaignRepositoryProvider)));
