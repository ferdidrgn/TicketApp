abstract class EventRepository {
  Future<void> initializeAndGetEventSeats(final String? eventId);
  Future<Map<String, Map<String, dynamic>>> getSeatStatusByEvent(final String? eventId);
  Future<List<String?>> getPurchasedSeatsByCustomerId(final String? eventId, final String? customerId);
  Future<void> updateSeatStatus(final String? eventId, final String? seatId, final String? status, {final String? customerId});
  Future<String?> getStageId(final String? eventId);
  Future<String?> getEventPrice(final String? eventId);
  Future<Map<String, String>?> getEventDate(final String? eventId, {final bool formatWithMonthName = false});
  Future<void> reserveSeat(final String? eventId, final String? seatId, final String? customerId);
  Future<void> cancelReservation(final String? eventId, final String? seatId);
}
