import '../../../core/common/base_state.dart';
import '../../../domain/entities/show.dart';

class ShowState extends BaseState {
  Show? show;
  List<Show>? shows;

  ShowState({
    this.show,
    this.shows = const [],
    super.isLoading,
    super.errorMessage,
  });

  @override
  ShowState copyWith({
    Show? show,
    List<Show>? shows,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ShowState(
      show: show ?? this.show,
      shows: shows ?? this.shows,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
