import 'package:ticketapp/core/common/base_notifier_with_base_state.dart';
import '../../../domain/useCase/seat/get_seats_by_stage_use_case_impl.dart';
import 'seats_state.dart';

class SeatsNotifier extends BaseNotifierWithBaseState<SeatsState> {
  final GetSeatsByStageUseCase getSeatsByStageUseCase;

  SeatsNotifier(this.getSeatsByStageUseCase) : super(SeatsState());

  Future<void> loadSeatsByStage(final String stageId) async {
    await handleOperation(
          () => getSeatsByStageUseCase.call(stageId),
      onSuccess: (final seats) =>
      state = state.copyWith(seats: seats),
    );
  }

}
