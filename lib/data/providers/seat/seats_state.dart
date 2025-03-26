import 'package:ticketapp/core/common/base_state.dart';

class SeatsState extends BaseState{
  Map<String, List<String>>? seats;

  SeatsState({
    Map<String, List<String>>? seats,
    super.isLoading = false,
    super.errorMessage,
  }) : seats = seats ?? {};

  @override
  SeatsState copyWith({
    Map<String, List<String>>? seats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SeatsState(
      seats: seats ?? this.seats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
