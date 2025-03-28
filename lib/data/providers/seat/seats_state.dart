import 'package:ticketapp/core/common/base_state.dart';

class SeatsState extends BaseState{
  Map<String, List<String>>? seats;

  SeatsState({
    final Map<String, List<String>>? seats,
    super.isLoading = false,
    super.errorMessage,
  }) : seats = seats ?? {};

  @override
  SeatsState copyWith({
    final Map<String, List<String>>? seats,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return SeatsState(
      seats: seats ?? this.seats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
