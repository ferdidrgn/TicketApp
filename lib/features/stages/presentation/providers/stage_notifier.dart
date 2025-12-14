import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_provider.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_state.dart';
import '../../domain/entities/stage.dart';

class StageNotifier extends BaseNotifier<StageState> {
  @override
  StageState initialState() => const StageState();

  Future<void> loadStages(final bool isLimit) => execute(
      () => ref.read(getStagesUseCaseProvider).call(isLimit),
      onSuccess: (final stages) => state = state.copyWith(dataList: stages));

  Future<void> loadStagesByIds(final List<String> stageIds) {
    if (stageIds.isEmpty) return Future.value([]);

    return execute(
      () => ref.read(getStageByIdUseCaseProvider).call(stageIds),
      onSuccess: (final stages) {
        if (!ref.mounted) return;
        state = state.copyWith(dataList: stages);
      },
    );
  }

  Future<void> searchStage(final String query) => execute(
      () => ref.read(getSearchStageUseCaseProvider).call(query),
      onSuccess: (final stages) => state = state.copyWith(dataList: stages));
}

extension StageStateX on StageState {
  /// Belirli bir stages'yi getir
  Stage? getStageById(final String stageId) {
    if (dataList == null) return null;
    try {
      return dataList!.firstWhere((final stage) => stage.id == stageId);
    } catch (_) {
      return null;
    }
  }

  /// Tüm stages ID'leri
  List<String> get stageIds =>
      dataList?.map((final stage) => stage.id).toList() ?? [];

  /// İlk stages veya null
  dynamic get firstStage =>
      dataList?.isNotEmpty == true ? dataList!.first : null;

  /// Son stages veya null
  dynamic get lastStage => dataList?.isNotEmpty == true ? dataList!.last : null;
}
