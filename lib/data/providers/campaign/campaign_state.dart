import 'package:ticketapp/core/common/base_loadable_state.dart';
import 'package:ticketapp/domain/entities/campaign.dart';

class CampaignState extends LoadableState<Campaign, List<Campaign>> {
  const CampaignState({
    super.dataSingle,
    super.dataList,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  CampaignState copyWith({
    final Campaign? dataSingle,
    final List<Campaign>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      CampaignState(
        dataSingle: dataSingle ?? this.dataSingle,
        dataList: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
