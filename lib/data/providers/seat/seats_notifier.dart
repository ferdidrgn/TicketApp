import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/data/providers/seat/seats_provider.dart';
import 'seats_state.dart';

class SeatsNotifier extends BaseNotifierWithNetworkChecker<SeatsState> {
  @override
  SeatsState initialState() => SeatsState();

  @override
  void reloadData() {
    // İstersen burada son kullanılan stageId varsa onunla yeniden yükleme yapabilirsin
  }

  Future<void> loadSeatsByStage(final String stageId) =>
      executeWithInternetCheck(
        () => ref.read(getSeatsByStageUseCaseProvider).call(stageId),
        onSuccess: (final seats) =>
            state = state.copyWith(seats: seats, errorMessage: null),
      );
}
