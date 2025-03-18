import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/campaign.dart';
import '../../../domain/useCase/campaign/get_campaigns_use_case_impl.dart';
import 'campaign_state.dart';

class CampaignNotifier extends StateNotifier<CampaignState> {
  final GetCampaignsUseCase getCampaignsUseCase;

  CampaignNotifier(this.getCampaignsUseCase) : super(CampaignState()) {
    loadCampaigns(); // Uygulama başladığında kampanyaları yükle
  }

  Future<void> loadCampaigns() async {
    _setLoadingState(true);
    final result = await getCampaignsUseCase.call();

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final campaigns) => _setCampaignsState(campaigns),
    );
  }

  void _setLoadingState(final bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage, isLoading: false);
  }

  void _setCampaignsState(final List<Campaign?> campaigns) {
    state = state.copyWith(campaigns: campaigns, isLoading: false);
  }
}
