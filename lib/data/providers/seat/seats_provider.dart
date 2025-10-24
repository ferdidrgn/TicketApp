import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/repository/seat/seat_repository_provider.dart';
import '../../../domain/useCase/seat/get_seats_by_stage_use_case_impl.dart';
import 'seats_notifier.dart';
import 'seats_state.dart';

final seatsProvider =
    NotifierProvider.autoDispose<SeatsNotifier, SeatsState>(SeatsNotifier.new);

// GetSeatsByStageUseCase provider
final getSeatsByStageUseCaseProvider = Provider<GetSeatsByStageUseCase>(
  (final ref) => GetSeatsByStageUseCaseImpl(ref.watch(seatRepositoryProvider)),
);
