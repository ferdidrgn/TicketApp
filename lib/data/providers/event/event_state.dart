class EventState {
  final String? price;
  final Map<String, String>? date;
  final String? stageId;
  final Map<String, Map<String, dynamic>>? seatStatus;
  final List<String?> purchasedSeats;
  final bool isLoading;
  final String? errorMessage;

  EventState({
    this.price,
    this.date,
    this.stageId,
    this.seatStatus,
    this.purchasedSeats = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EventState copyWith({
    final String? price,
    final Map<String, String>? date,
    final String? stageId,
    final Map<String, Map<String, dynamic>>? seatStatus,
    final List<String?>? purchasedSeats,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return EventState(
      price: price ?? this.price,
      date: date ?? this.date,
      stageId: stageId ?? this.stageId,
      seatStatus: seatStatus ?? this.seatStatus,
      purchasedSeats: purchasedSeats ?? this.purchasedSeats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
