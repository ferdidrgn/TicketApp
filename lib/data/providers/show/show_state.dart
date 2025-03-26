import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/common/base_state.dart';
import '../../model/show_model.dart';

@freezed
class ShowState extends BaseState {
  final ShowModel? show;
  final List<ShowModel?> shows;

  const ShowState({
    this.show,
    this.shows = const [],
    super.isLoading,
    super.errorMessage,
  });

  @override
  ShowState copyWith({
    final ShowModel? show,
    final List<ShowModel?>? shows,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return ShowState(
      show: show ?? this.show,
      shows: shows ?? this.shows,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
