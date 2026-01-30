import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'processing_seats_provider.g.dart';

@riverpod
class ProcessingSeats extends _$ProcessingSeats {
  @override
  Set<String> build() => {};

  void add(final String seatId) {
    state = {...state, seatId};
  }

  void remove(final String seatId) {
    state = {...state.where((final id) => id != seatId)};
  }
}