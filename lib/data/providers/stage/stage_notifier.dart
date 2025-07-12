import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/useCase/stage/get_search_stage_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stage_by_id_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stages_use_case_impl.dart';
import 'stage_state.dart';

class StageNotifier extends BaseNotifierWithNetworkChecker<StageState> {
  final GetStagesUseCase _getStagesUseCase;
  final GetStagesByIdsUseCase _getStagesByIdsUseCase;
  final GetSearchStageUseCase _getSearchStageUseCase;

  StageNotifier(
    final InternetService internetService,
    this._getStagesUseCase,
    this._getStagesByIdsUseCase,
    this._getSearchStageUseCase,
  ) : super(internetService, const StageState());

  @override
  void reloadData() => loadStages(false);

  Future<void> loadStages(final isLimit) => executeWithInternetCheck(
        () => _getStagesUseCase.call(isLimit),
        onSuccess: (final stages) => state = state.copyWith(dataList: stages),
      );

  Future<void> loadStagesByIds(final List<String> stageIds) =>
      executeWithInternetCheck(
        () => _getStagesByIdsUseCase.call(stageIds),
        onSuccess: (final stages) => state = state.copyWith(dataList: stages),
      );

  Future<void> searchStage(final String query) => executeWithInternetCheck(
        () => _getSearchStageUseCase.call(query),
        onSuccess: (final stages) => state = state.copyWith(dataList: stages),
      );
}
