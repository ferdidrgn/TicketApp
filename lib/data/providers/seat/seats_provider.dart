import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/seat/get_seats_by_stage_use_case_impl.dart';
import '../../repository/event/event_repository_provider.dart';
import 'seats_notifier.dart';
import 'seats_state.dart';

final seatsProvider =
    StateNotifierProvider<SeatsNotifier, SeatsState>((final ref) {
  return SeatsNotifier(ref.watch(getSeatsByStageUseCaseProvider));
});

// GetSeatsByStageUseCase provider
final getSeatsByStageUseCaseProvider =
    Provider<GetSeatsByStageUseCase>((final ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return GetSeatsByStageUseCaseImpl(repository);
});
