import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../domain/entities/campaign.dart';
import 'campaign_provider.dart';
import 'campaign_state.dart';

class CampaignNotifier extends BaseNotifierWithNetworkChecker<CampaignState> {
  @override
  CampaignState initialState() => const CampaignState();

  @override
  void reloadData() => loadCampaigns();

  Future<void> loadCampaigns() => executeWithInternetCheck(
        () => ref.read(getCampaignsUseCaseProvider).call(),
        onSuccess: (final campaigns) =>
            state = state.copyWith(dataList: campaigns),
      );
}

extension CampaignStateX on CampaignState {
  /// Campaign listesi boş mu?
  bool get hasCampaigns => dataList != null && dataList!.isNotEmpty;

  /// Belirli bir ID var mı?
  bool hasCampaign(final String id) => getCampaignById(id) != null;

  /// Campaign sayısı
  int get campaignCount => dataList?.length ?? 0;

  /// ID’ye göre campaign bul
  Campaign? getCampaignById(final String id) {
    if (dataList == null) return null;
    try {
      return dataList!.firstWhere((final c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
