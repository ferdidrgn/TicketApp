import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/show.dart';

class ShowState extends LoadableState<Show, List<Show>> {
  const ShowState({
    final List<Show>? shows,
    final Show? show,
    super.isLoading = false,
    super.errorMessage,
  }) : super(dataSingle: show, dataList: shows);

  @override
  ShowState copyWith({
    final bool? isLoading,
    final String? errorMessage,
    final Show? dataSingle,
    final List<Show>? dataList,
  }) {
    return ShowState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      show: dataSingle ?? this.dataSingle,
      shows: dataList ?? this.dataList,
    );
  }
}
