import 'package:ticketapp/core/common/base_state.dart';

class SeatsState extends BaseState{
  final Map<String, List<String?>?> seats;

  SeatsState({
    super.isLoading = false,
    super.errorMessage,
    final Map<String, List<String?>?>? seats,
  }) : seats = seats ?? {};

  @override
  SeatsState copyWith({
    final Map<String, List<String?>?>? seats,
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
