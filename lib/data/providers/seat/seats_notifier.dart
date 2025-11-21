import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/data/providers/seat/seats_provider.dart';
import 'seats_state.dart';

class SeatsNotifier extends BaseNotifier<SeatsState> {
  @override
  SeatsState initialState() => SeatsState();

  Future<void> loadSeatsByStage(final String stageId) =>
      execute(
        () => ref.read(getSeatsByStageUseCaseProvider).call(stageId),
        onSuccess: (final seats) =>
            state = state.copyWith(seats: seats, errorMessage: null),
      );
}
