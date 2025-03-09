import '../../model/show_model.dart';

class ShowState {
  final List<ShowModel?> shows;
  final ShowModel? show;
  final bool isLoading;
  final String? errorMessage;

  ShowState({
    this.shows = const [],
    this.show,
    this.isLoading = false,
    this.errorMessage,
  });

  ShowState copyWith({
    final List<ShowModel?>? shows,
    final ShowModel? show,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return ShowState(
      shows: shows ?? this.shows,
      show: show ?? this.show,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
