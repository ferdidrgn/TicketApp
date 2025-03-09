import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/seat/get_seats_by_stage_use_case_impl.dart';
import 'seats_state.dart';

class SeatsNotifier extends StateNotifier<SeatsState> {
  final GetSeatsByStageUseCase getSeatsByStageUseCase;

  SeatsNotifier(this.getSeatsByStageUseCase) : super(SeatsState());

  Future<void> loadSeatsByStage(final String stageId) async {
    _setLoadingState(true);
    final result = await getSeatsByStageUseCase.call(stageId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final seats) => _setSeatsState(seats),
    );
  }

  void _setLoadingState(final bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage, isLoading: false);
  }

  void _setSeatsState(final Map<String, List<String?>> seats) {
    state = state.copyWith(seats: seats, isLoading: false);
  }
}
