import '../../../../core/base/base_loadable_state.dart';
import '../../domain/entities/show.dart';

class ShowState extends LoadableState<Show, List<Show>> {
  const ShowState({
    super.dataList,
    super.dataSingle,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  ShowState copyWith({
    final List<Show>? dataList,
    final Show? dataSingle,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      ShowState(
        dataList: dataList ?? this.dataList,
        dataSingle: dataSingle ?? this.dataSingle,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}
