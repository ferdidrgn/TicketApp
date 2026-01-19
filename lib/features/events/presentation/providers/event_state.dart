import 'package:flutter/foundation.dart';
import '../../../../core/base/base_loadable_state.dart';
import '../../domain/entities/event.dart';

typedef EventSeatStatus = Map<String, Map<String, dynamic>?>;

@immutable
class EventState extends LoadableState<Event, List<Event>> {
  // Statik veriler (bir kez yüklenir)
  final String? eventPrice;
  final Map<String, String>? eventDate;
  final String? stageId;

  // Context bilgileri (constructor'dan gelir, değişmez)
  final String eventId;
  final String showId;
  final String customerId;

  // Real-time veri (stream'den gelir)
  final EventSeatStatus seatStatus;

  // Kullanıcının bu etkinlik için önceden satın almış olduğu koltuk sayısı
  final int purchasedSeatCount;

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

  // Önceden hesaplanmış ve önbelleğe alınmış koltuk düzeni (CPU Optimizasyonu)
  final Map<String, List<String>> seatLayout;

  const EventState({
    required this.eventId,
    required this.showId,
    required this.customerId,
    this.eventPrice,
    this.eventDate,
    this.stageId,
    this.seatStatus = const {},
    this.selectedSeats = const {},
    this.remainingTime = 600,
    this.totalPrice = 0.0,
    this.paymentSuccessful = false,
    this.processingSeats = const {},
    this.firstReservationTime,
    this.seatLayout = const {},
    this.purchasedSeatCount = 0,
    super.dataSingle,
    super.dataList,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  EventState copyWith({
    final String? eventId,
    final String? showId,
    final String? customerId,
    final Event? dataSingle,
    final List<Event>? dataList,
    final String? eventPrice,
    final Map<String, String>? eventDate,
    final String? stageId,
    final EventSeatStatus? seatStatus,
    final int? purchasedSeatCount,
    final Set<String>? selectedSeats,
    final int? remainingTime,
    final double? totalPrice,
    final bool? paymentSuccessful,
    final Set<String>? processingSeats,
    final DateTime? firstReservationTime,
    final Map<String, List<String>>? seatLayout,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      EventState(
        eventId: eventId ?? this.eventId,
        showId: showId ?? this.showId,
        stageId: stageId ?? this.stageId,
        customerId: customerId ?? this.customerId,
        dataSingle: dataSingle ?? this.dataSingle,
        dataList: dataList ?? this.dataList,
        eventPrice: eventPrice ?? this.eventPrice,
        eventDate: eventDate ?? this.eventDate,
        seatStatus: seatStatus ?? this.seatStatus,
        purchasedSeatCount: purchasedSeatCount ?? this.purchasedSeatCount,
        selectedSeats: selectedSeats ?? this.selectedSeats,
        remainingTime: remainingTime ?? this.remainingTime,
        totalPrice: totalPrice ?? this.totalPrice,
        paymentSuccessful: paymentSuccessful ?? this.paymentSuccessful,
        processingSeats: processingSeats ?? this.processingSeats,
        firstReservationTime: firstReservationTime ?? this.firstReservationTime,
        seatLayout: seatLayout ?? this.seatLayout,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
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
