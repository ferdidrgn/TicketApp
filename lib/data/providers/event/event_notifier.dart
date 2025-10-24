import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/data/model/ticket_model.dart';
import '../ticket/ticket_provider.dart';
import 'event_provider.dart';
import 'event_state.dart';

class EventNotifier extends BaseNotifierWithNetworkChecker<SeatSelectionState> {
  Timer? _reservationTimer;
  StreamSubscription? _seatStatusSubscription;
  bool _isDisposed = false;

  @override
  SeatSelectionState initialState() =>
      throw UnimplementedError('Use initializeWithParams instead');

  // State'i parametrelerle başlat
  void initializeWithParams({
    required final String eventId,
    required final String showId,
    required final String customerId,
  }) {
    state = SeatSelectionState(
      eventId: eventId,
      showId: showId,
      customerId: customerId,
      isLoading: true,
    );
    _loadInitialData();
  }

  @override
  void reloadData() => _loadInitialData();

  // Başlangıç verilerini yükle
  Future<void> _loadInitialData() async {
    // 1. Stream'i hemen başlat
    _subscribeSeatStatus();

    // 2. Statik event verilerini (Tarih, Fiyat, StageId) al
    try {
      // ✅ getEventDateUseCaseProvider yerine getEventDetailsUseCaseProvider kullandığımızı varsayalım
      final detailsResult =
          await ref.read(getEventDetailsUseCaseProvider).call(state.eventId);

      if (!_isDisposed) {
        detailsResult.fold(
          (final failure) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: "Etkinlik detayları yüklenemedi.",
            );
          },
          (final details) {
            // ✅ Gelen Fiyat ve StageId'yi state'e işle
            final newEventPrice = details?['eventPrice'] as String?;
            final newSeatPrice = double.tryParse(newEventPrice ?? "0") ?? 0;

            // ✅ Fiyat yüklendiğinde, totalPrice'ı yeniden hesapla
            final newTotalPrice = state.selectedSeats.length * newSeatPrice;

            state = state.copyWith(
              eventDate: details?['eventDate'] as Map<String, String>?,
              eventPrice: newEventPrice,
              stageId: details?['stageId'] as String?,
              totalPrice: newTotalPrice,
              // ✅ Fiyatı güncelle
              isLoading: false,
            );
          },
        );
      }
    } catch (e) {
      if (!_isDisposed) state = state.copyWith(isLoading: false);
    }

    // 3. Timer'ı başlat
    _startReservationTimer();
  }

  // Seat status stream subscription
  void _subscribeSeatStatus() {
    _seatStatusSubscription?.cancel();

    final stream =
        ref.read(getEventSeatStatusStreamUseCaseProvider).call(state.eventId);

    _seatStatusSubscription = stream.listen(
      (final seatStatusMap) {
        if (_isDisposed) return; // Disposed ise işlem yapma

        // --- GÜNCELLENEN BÖLÜM ---

        // 1. Stream'den gelen veriye göre yerel seçili koltukları bul
        final currentReservations = <String>{};
        for (final entry in seatStatusMap.entries) {
          final seatId = entry.key;
          final seatInfo = entry.value;

          if (seatInfo != null &&
              seatInfo['status'] == 'reserved' &&
              seatInfo['customerId'] == state.customerId)
            currentReservations.add(seatId);
        }

        // 2. Fiyatı, mevcut state'teki koltuk fiyatına göre yeniden hesapla
        // (Bu fiyat _loadInitialData'da yüklenecek)
        final newTotalPrice = currentReservations.length * state.seatPrice;

        // 3. State'i güncelle
        state = state.copyWith(
          seatStatus: seatStatusMap,
          selectedSeats: currentReservations,
          // ✅ Yerel seti senkronize et
          totalPrice: newTotalPrice,
          // ✅ Fiyatı senkronize et
          errorMessage: null,
          isLoading: false,
        );
        // --- GÜNCELLEME BİTTİ ---
      },
      onError: (final e) {
        if (!_isDisposed)
          state = state.copyWith(
            errorMessage: e.toString(),
            isLoading: false,
          );
      },
    );
  }

  // Rezervasyon timer'ı
  void _startReservationTimer() {
    _reservationTimer?.cancel();
    _reservationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (final timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        if (!state.isTimeUp) {
          state = state.copyWith(remainingTime: state.remainingTime - 1);
        } else {
          timer.cancel();
          _handleTimeUp();
        }
      },
    );
  }

  // Süre dolduğunda
  void _handleTimeUp() {
    cancelAllReservations();
    if (!_isDisposed) {
      state = state.copyWith(
        errorMessage: "Süreniz doldu. Rezervasyonlarınız iptal edildi.",
        selectedSeats: {},
        totalPrice: 0,
      );
    }
  }

  // Koltuk seçimi toggle
  Future<void> toggleSeatSelection(final String seatId) async {
    final currentSelected = Set<String>.from(state.selectedSeats);

    // Koltuk zaten seçiliyse, kaldır
    if (currentSelected.contains(seatId)) {
      await _removeSeat(seatId, currentSelected);
      return;
    }

    // Maximum 3 koltuk kontrolü
    if (currentSelected.length >= 3) {
      _showTemporaryError("En fazla 3 koltuk seçebilirsiniz.");
      return;
    }

    // Yeni koltuk ekle
    await _addSeat(seatId, currentSelected);
  }

  // Koltuk ekleme
  Future<void> _addSeat(
    final String seatId,
    final Set<String> currentSelected,
  ) async {
    await executeWithInternetCheck(
      () => ref.read(attemptReservationUseCaseProvider).call(
            state.eventId,
            seatId,
            state.customerId,
          ),
      onSuccess: (final success) {
        if (!_isDisposed && success) {
          currentSelected.add(seatId);
          state = state.copyWith(
            selectedSeats: currentSelected,
            totalPrice: state.totalPrice + state.seatPrice,
          );
        } else if (!_isDisposed) {
          _showTemporaryError("Koltuk başkası tarafından seçildi.");
        }
      },
    );
  }

  // Koltuk çıkarma
  Future<void> _removeSeat(
    final String seatId,
    final Set<String> currentSelected,
  ) async {
    currentSelected.remove(seatId);

    if (!_isDisposed) {
      state = state.copyWith(
        selectedSeats: currentSelected,
        totalPrice: state.totalPrice - state.seatPrice,
      );
    }

    await ref.read(releaseReservationUseCaseProvider).call(
          state.eventId,
          seatId,
          state.customerId,
        );
  }

  // Ödeme işlemi
  Future<void> processPayment(final String paymentMethod) async {
    if (!state.hasSelectedSeats) return;

    state = state.copyWith(isLoading: true);

    await executeWithInternetCheck(
      () async {
        // 1. Satın alma işlemini onayla
        final confirmResult =
            await ref.read(confirmPurchaseUseCaseUseCaseProvider).call(
                  state.eventId,
                  state.selectedSeats.toList(),
                  state.customerId,
                );

        if (confirmResult.isLeft()) return confirmResult;

        // 2. Bilet oluştur
        final ticket = _createTicket(paymentMethod);
        final ticketResult =
            await ref.read(createTicketUseCaseProvider).call(ticket);

        return ticketResult;
      },
      onSuccess: (final _) {
        _reservationTimer?.cancel();
        if (!_isDisposed) {
          state = state.copyWith(
            selectedSeats: {},
            totalPrice: 0,
            paymentSuccessful: true,
            isLoading: false,
          );
        }
      },
    );
  }

  // Bilet oluştur
  TicketModel _createTicket(final String paymentMethod) {
    final now = DateTime.now();
    return TicketModel(
      createdAt: now.toString(),
      updatedAt: now.toString(),
      id: '',
      showId: state.showId,
      customerId: state.customerId,
      stageId: state.stageId ?? '',
      eventId: state.eventId,
      orderPrice: state.totalPrice.toString(),
      orderMethod: paymentMethod,
      isPast: false,
    );
  }

  // Tüm rezervasyonları iptal et
  Future<void> cancelAllReservations() async {
    if (!state.hasSelectedSeats) return;

    final cancellationFutures = <Future<dynamic>>[];

    for (final seatId in state.selectedSeats) {
      cancellationFutures.add(
        ref.read(releaseReservationUseCaseProvider).call(
              state.eventId,
              seatId,
              state.customerId,
            ),
      );
    }

    await Future.wait(cancellationFutures);
  }

  // Geçici hata mesajı göster (2 saniye sonra temizle)
  void _showTemporaryError(final String message) {
    if (_isDisposed) return;

    state = state.copyWith(errorMessage: message);
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        state = state.copyWith(errorMessage: null);
      }
    });
  }

  // Ödeme başarı flag'ini sıfırla
  void resetPaymentSuccess() {
    if (!_isDisposed) {
      state = state.copyWith(paymentSuccessful: false);
    }
  }

  // Cleanup
  void cleanup() {
    _isDisposed = true;
    _reservationTimer?.cancel();
    _seatStatusSubscription?.cancel();
  }
}

// Helper method to initialize with params
extension EventNotifierX on WidgetRef {
  void initializeEventNotifier({
    required final String eventId,
    required final String showId,
    required final String customerId,
  }) {
    read(eventNotifierProvider.notifier).initializeWithParams(
      eventId: eventId,
      showId: showId,
      customerId: customerId,
    );
  }
}
