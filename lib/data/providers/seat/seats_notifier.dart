import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/useCase/seat/get_seats_by_stage_use_case_impl.dart';
import 'seats_state.dart';

class SeatsNotifier extends BaseNotifierWithNetworkChecker<SeatsState> {
  final GetSeatsByStageUseCase _getSeatsByStageUseCase;

  SeatsNotifier(final InternetService internetService, this._getSeatsByStageUseCase)
      : super(internetService, SeatsState());

  @override
  void reloadData() {
    // İstersen burada son kullanılan stageId varsa onunla yeniden yükleme yapabilirsin
  }

  Future<void> loadSeatsByStage(final String stageId) =>
      executeWithInternetCheck(
            () => _getSeatsByStageUseCase.call(stageId),
        onSuccess: (final seats) => state = state.copyWith(seats: seats, errorMessage: null),
      );
}
