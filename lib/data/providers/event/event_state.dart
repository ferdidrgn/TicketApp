import 'package:flutter/foundation.dart';
import 'package:ticketapp/core/common/base_state.dart';

typedef EventSeatStatus = Map<String, Map<String, dynamic>?>;

@immutable
class SeatSelectionState extends BaseState {
  // Statik veriler (bir kez yüklenir)
  final String? eventPrice; // ✅ Fiyat hesaplaması için GEREKLİ
  final Map<String, String>? eventDate; // ✅ GEREKLİ
  final String? stageId; // ✅ Bilet oluşturmak için GEREKLİ

  // Context bilgileri (constructor'dan gelir, değişmez)
  final String eventId;
  final String showId;
  final String customerId;

  // Real-time veri (stream'den gelir)
  final EventSeatStatus seatStatus;

  // Oturum (Session) verisi
  final Set<String> selectedSeats;
  final int remainingTime;
  final double totalPrice;

  // Ödeme başarılı flag'i
  final bool paymentSuccessful;

  // Hangi koltukların ağ işlemi (ekleme/kaldırma) beklediğini tutar
  final Set<String> processingSeats;

  // Kullanıcının bu oturumdaki ilk rezervasyonunun zamanı
  final DateTime? firstReservationTime;

  const SeatSelectionState({
    required this.eventId,
    required this.showId,
    required this.customerId,
    this.eventPrice, // ✅
    this.eventDate,
    this.stageId, // ✅
    this.seatStatus = const {},
    this.selectedSeats = const {},
    this.remainingTime = 10,
    this.totalPrice = 0.0,
    this.paymentSuccessful = false,
    this.processingSeats = const {},
    this.firstReservationTime,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  SeatSelectionState copyWith({
    final String? eventId,
    final String? showId,
    final String? customerId,
    final String? eventPrice,
    final Map<String, String>? eventDate,
    final String? stageId,
    final EventSeatStatus? seatStatus,
    final Set<String>? selectedSeats,
    final int? remainingTime,
    final double? totalPrice,
    final bool? paymentSuccessful,
    final Set<String>? processingSeats,
    final DateTime? firstReservationTime,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      SeatSelectionState(
        eventId: eventId ?? this.eventId,
        showId: showId ?? this.showId,
        stageId: stageId ?? this.stageId,
        customerId: customerId ?? this.customerId,
        eventPrice: eventPrice ?? this.eventPrice,
        eventDate: eventDate ?? this.eventDate,
        seatStatus: seatStatus ?? this.seatStatus,
        selectedSeats: selectedSeats ?? this.selectedSeats,
        remainingTime: remainingTime ?? this.remainingTime,
        totalPrice: totalPrice ?? this.totalPrice,
        paymentSuccessful: paymentSuccessful ?? this.paymentSuccessful,
        processingSeats: processingSeats ?? this.processingSeats,
        firstReservationTime: firstReservationTime ?? this.firstReservationTime,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );

  // Computed properties
  double get seatPrice => double.tryParse(eventPrice ?? "0") ?? 0;

  bool get hasSelectedSeats => selectedSeats.isNotEmpty;

  bool get isTimeUp => remainingTime <= 0;

  String get formattedTime {
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
