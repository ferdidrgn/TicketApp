import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/campaign/get_campaigns_use_case_impl.dart';
import '../../model/campaing_model.dart';
import 'campaign_state.dart';

class CampaignNotifier extends StateNotifier<CampaignState> {
  final GetCampaignsUseCase getCampaignsUseCase;

  CampaignNotifier(this.getCampaignsUseCase) : super(CampaignState());

  Future<void> loadCampaigns() async {
    _setLoadingState(true);

    try {
      final result = await getCampaignsUseCase.call();
      result.fold(
        (final failure) => _setErrorState(failure.message),
        (final campaignList) => _setCampaignsState(campaignList ?? []),
      );
    } catch (e) {
      _setErrorState("Beklenmeyen bir hata oluştu");
    } finally {
      _setLoadingState(false);
    }
  }

  void _setCampaignsState(final List<CampaignModel?> campaigns) {
    state = state.copyWith(campaigns: campaigns, errorMessage: null);
  }

  void _setErrorState(final String message) {
    state = state.copyWith(errorMessage: message);
  }

  void _setLoadingState(final isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }
}
