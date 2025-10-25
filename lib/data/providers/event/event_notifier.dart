import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isProcessingPayment = false;

  @override
  SeatSelectionState initialState() =>
      throw UnimplementedError('Use initializeWithParams instead');

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
      remainingTime: 600, // Sayacın 10:00'dan başlamasını garantile
    );
    _loadInitialData();
  }

  @override
  void reloadData() => _loadInitialData();

  Future<void> _loadInitialData() async {
    _subscribeSeatStatus(); // Akıllı mantık

    try {
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
            final newEventPrice = details?['eventPrice'] as String?;
            state = state.copyWith(
              eventDate: details?['eventDate'] as Map<String, String>?,
              eventPrice: newEventPrice,
              stageId: details?['stageId'] as String?,
              // isLoading: false, // Stream'den ilk veri gelene kadar bekle
            );
          },
        );
      }
    } catch (e) {
      if (!_isDisposed) state = state.copyWith(isLoading: false);
    }

    _startReservationTimer(); // Aptal sayaç
  }

  void _subscribeSeatStatus() {
    _seatStatusSubscription?.cancel();

    final stream =
        ref.read(getEventSeatStatusStreamUseCaseProvider).call(state.eventId);

    _seatStatusSubscription = stream.listen(
      (final seatStatusMap) {
        if (_isDisposed) return;

        final currentReservations = <String>{};

        for (final entry in seatStatusMap.entries) {
          final seatId = entry.key;
          final seatInfo = entry.value;

          if (seatInfo != null &&
              seatInfo['status'] == 'reserved' &&
              seatInfo['customerId'] == state.customerId) {
            currentReservations.add(seatId);
          }
        }

        final newTotalPrice = currentReservations.length * state.seatPrice;

        final currentLayout = state.seatLayout.isEmpty ||
                state.seatStatus.keys.length != seatStatusMap.keys.length
            ? _groupSeatsFromStatus(
                seatStatusMap.cast<String, Map<String, dynamic>?>())
            : state.seatLayout;

        state = state.copyWith(
          seatStatus: seatStatusMap,
          selectedSeats: currentReservations,
          totalPrice: newTotalPrice,
          seatLayout: currentLayout,
          errorMessage: null,
          isLoading: false,
        );
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

  void _startReservationTimer() {
    _reservationTimer?.cancel();
    _reservationTimer =
        Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (_isDisposed || state.remainingTime <= 0) {
        timer.cancel();
        return;
      }

      state = state.copyWith(remainingTime: state.remainingTime - 1);

      if (state.remainingTime <= 0) _handleTimeUp();
    });
  }

  // Süre doldu (Değişiklik yok)
  void _handleTimeUp() {
    cancelAllReservations(); // Önce rezervasyonları iptal et
    if (!_isDisposed) {
      state = state.copyWith(
        errorMessage: "Süreniz doldu. Rezervasyonlarınız iptal edildi.",
        selectedSeats: {},
        totalPrice: 0,
        firstReservationTime: null,
        remainingTime: 600, // Sayacı bir sonraki oturum için sıfırla
      );
    }
  }

  // Koltuk seçimi (Değişiklik yok)
  Future<void> toggleSeatSelection(final String seatId) async {
    if (state.processingSeats.contains(seatId)) return;

    final isCurrentlySelected = state.selectedSeats.contains(seatId);

    if (isCurrentlySelected) {
      await _removeSeat(seatId);
    } else {
      final totalPendingAndSelected =
          state.selectedSeats.length + state.processingSeats.length;

      if (totalPendingAndSelected >= 3) {
        _showTemporaryError("En fazla 3 koltuk seçebilirsiniz.");
        return;
      }

      await _addSeat(seatId);
    }
  }

  // Koltuk ekle (Değişiklik yok)
  Future<void> _addSeat(final String seatId) async {
    if (_isDisposed) return;

    state = state.copyWith(
      processingSeats: {...state.processingSeats, seatId},
      errorMessage: null,
    );

    try {
      final result = await ref.read(attemptReservationUseCaseProvider).call(
            state.eventId,
            seatId,
            state.customerId,
          );

      result.fold(
        (final failure) {
          if (!_isDisposed) _showTemporaryError(failure.message);
        },
        (final success) {
          if (!_isDisposed && !success)
            _showTemporaryError("Koltuk başkası tarafından seçildi.");
        },
      );
    } catch (e) {
      if (!_isDisposed)
        _showTemporaryError("Rezervasyon hatası: ${e.toString()}");
    } finally {
      if (!_isDisposed)
        state = state.copyWith(
          processingSeats: {...state.processingSeats}..remove(seatId),
        );
    }
  }

  // Koltuk çıkar (Değişiklik yok)
  Future<void> _removeSeat(final String seatId) async {
    if (_isDisposed) return;

    final newSelectedSeats = Set<String>.from(state.selectedSeats)
      ..remove(seatId);
    final newTotalPrice = newSelectedSeats.length * state.seatPrice;
    final newProcessingSeats = {...state.processingSeats, seatId};

    state = state.copyWith(
      selectedSeats: newSelectedSeats,
      totalPrice: newTotalPrice,
      processingSeats: newProcessingSeats,
      errorMessage: null,
    );

    try {
      final result = await ref
          .read(releaseReservationUseCaseProvider)
          .call(state.eventId, seatId, state.customerId);

      result.fold(
        (final failure) {
          if (!_isDisposed) _showTemporaryError(failure.message);
        },
        (final _) {},
      );
    } catch (e) {
      if (!_isDisposed) _showTemporaryError("İptal hatası: ${e.toString()}");
    } finally {
      if (!_isDisposed)
        state = state.copyWith(
            processingSeats: {...state.processingSeats}..remove(seatId));
    }
  }

  // CPU Optimizasyonu (Değişiklik yok)
  Map<String, List<String>> _groupSeatsFromStatus(
      final Map<String, Map<String, dynamic>?> seatStatus) {
    final seatsByRow = <String, List<String>>{};
    for (final seatId in seatStatus.keys) {
      if (seatId.isEmpty) continue;
      final row = seatId[0];
      seatsByRow.putIfAbsent(row, () => []).add(seatId);
    }
    final sortedRows = seatsByRow.keys.toList()..sort();
    final result = <String, List<String>>{};
    for (final row in sortedRows) {
      final seats = seatsByRow[row]!;
      seats.sort((final a, final b) {
        final numA = int.tryParse(a.substring(1)) ?? 0;
        final numB = int.tryParse(b.substring(1)) ?? 0;
        return numA.compareTo(numB);
      });
      result[row] = seats;
    }
    return result;
  }

  // Ödeme (Değişiklik yok)
  Future<void> processPayment(
    final String paymentMethod,
    final SeatSelectionState paymentSnapshot,
  ) async {
    if (_isDisposed) return;

    if (_isProcessingPayment) {
      _showTemporaryError("Ödeme zaten işleniyor.");
      return;
    }
    _isProcessingPayment = true;

    final seatsToPurchase = List<String>.from(paymentSnapshot.selectedSeats);
    final double priceToPay = paymentSnapshot.totalPrice;

    if (seatsToPurchase.isEmpty) {
      _showTemporaryError("Sepetiniz boş.");
      _isProcessingPayment = false;
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      await executeWithInternetCheck(
        () async {
          final confirmResult = await ref
              .read(confirmPurchaseUseCaseUseCaseProvider)
              .call(state.eventId, seatsToPurchase, state.customerId);

          if (confirmResult.isLeft()) return confirmResult;

          final ticket = _createTicket(paymentMethod, priceToPay);
          final ticketResult =
              await ref.read(createTicketUseCaseProvider).call(ticket);

          return ticketResult;
        },
        onSuccess: (final _) {
          _reservationTimer?.cancel();
          if (!_isDisposed)
            state = state.copyWith(
              paymentSuccessful: true,
              isLoading: false,
              firstReservationTime: null,
              remainingTime: 600,
            );
        },
      );
    } catch (e) {
      if (!_isDisposed)
        _showTemporaryError("Ödeme sırasında beklenmedik bir hata oluştu.");
    } finally {
      _isProcessingPayment = false;
    }
  }

  // Bilet oluştur (Değişiklik yok)
  TicketModel _createTicket(
    final String paymentMethod,
    final double totalPriceSnapshot,
  ) {
    final now = DateTime.now();
    String finalPrice;
    String finalMethod = paymentMethod;

    if (paymentMethod == 'free_ticket') {
      finalPrice = "0.0";
    } else if (paymentMethod.startsWith('coffee_') ||
        paymentMethod == 'free_coffee') {
      finalPrice =
          paymentMethod.split('_').last.replaceAll(RegExp(r'[^0-9]'), '');
      if (finalPrice.isEmpty) finalPrice = "20.0";
      finalMethod = 'coffee_donation';
    } else {
      finalPrice = totalPriceSnapshot.toStringAsFixed(2);
    }

    return TicketModel(
      createdAt: now.toString(),
      updatedAt: now.toString(),
      id: '',
      showId: state.showId,
      customerId: state.customerId,
      stageId: state.stageId ?? '',
      eventId: state.eventId,
      orderPrice: finalPrice,
      orderMethod: finalMethod,
      isPast: false,
    );
  }

  // Tüm rezervasyonları iptal et (Değişiklik yok)
  Future<void> cancelAllReservations() async {
    if (!state.hasSelectedSeats) return;

    final cancellationFutures = <Future<dynamic>>[];
    final seatsToCancel = Set<String>.from(state.selectedSeats);

    for (final seatId in seatsToCancel) {
      cancellationFutures.add(ref
          .read(releaseReservationUseCaseProvider)
          .call(state.eventId, seatId, state.customerId));
    }

    try {
      await Future.wait(cancellationFutures);
    } catch (e) {
      print("Tüm rezervasyonları iptal ederken hata oluştu: $e");
    }
  }

  // Geçici hata göster (Değişiklik yok)
  void _showTemporaryError(final String message) {
    if (_isDisposed) return;

    state = state.copyWith(errorMessage: message);
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed && state.errorMessage == message)
        state = state.copyWith(errorMessage: null);
    });
  }

  // Ödeme başarısını sıfırla (Değişiklik yok)
  void resetPaymentSuccess() {
    if (!_isDisposed) state = state.copyWith(paymentSuccessful: false);
  }

  // Temizle (Değişiklik yok)
  void cleanup() {
    _isDisposed = true;
    _reservationTimer?.cancel();
    _seatStatusSubscription?.cancel();
  }
}

// Helper (Değişiklik yok)
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
