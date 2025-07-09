import 'package:ticketapp/core/common/base_loadable_state.dart';
import 'package:ticketapp/domain/entities/campaign.dart';

class CampaignState extends LoadableState<Campaign, List<Campaign>> {
  const CampaignState({
    final Campaign? campaign,
    final List<Campaign>? campaigns,
    super.isLoading = false,
    super.errorMessage,
  }) : super(dataSingle: campaign, dataList: campaigns);

  @override
  CampaignState copyWith({
    final Campaign? dataSingle,
    final List<Campaign>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return CampaignState(
      campaign: dataSingle ?? this.dataSingle,
      campaigns: dataList ?? this.dataList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
