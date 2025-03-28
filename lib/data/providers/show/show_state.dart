import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/show.dart';

class ShowState extends LoadableState<List<Show>> {
  const ShowState({
    bool isLoading = false,
    String? errorMessage,
    List<Show>? shows,
  }) : super(
    isLoading: isLoading,
    errorMessage: errorMessage,
    data: shows,
  );

  @override
  ShowState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Show>? shows,
  }) {
    return ShowState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      shows: shows ?? this.data,
    );
  }
}
