class SeatsState {
  final Map<String, List<String?>> seats;
  final bool isLoading;
  final String? errorMessage;

  SeatsState({
    this.isLoading = false,
    this.errorMessage,
    final Map<String, List<String?>>? seats,
  }) : seats = seats ?? {};

  SeatsState copyWith({
    final Map<String, List<String?>>? seats,
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