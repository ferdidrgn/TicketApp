import 'package:ticketapp/core/common/base_notifier.dart';
import '../../../domain/useCase/seat/get_seats_by_stage_use_case_impl.dart';
import 'seats_state.dart';

class SeatsNotifier extends BaseNotifier<SeatsState> {
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
