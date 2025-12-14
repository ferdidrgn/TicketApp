import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/seat/data/repositories/seat_repository_provider.dart';
import 'package:ticketapp/features/seat/presentation/providers/seats_notifier.dart';
import '../../domain/usecases/get_seats_by_stage_use_case_impl.dart';
import 'seats_state.dart';

final seatsProvider =
    NotifierProvider.autoDispose<SeatsNotifier, SeatsState>(SeatsNotifier.new);

// GetSeatsByStageUseCase provider
final getSeatsByStageUseCaseProvider = Provider<GetSeatsByStageUseCase>(
    (final ref) =>
        GetSeatsByStageUseCaseImpl(ref.watch(seatRepositoryProvider)));
