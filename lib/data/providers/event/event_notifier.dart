import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/domain/entities/ticket.dart';
import '../ticket/ticket_provider.dart';
import 'event_provider.dart';
import 'event_state.dart';

class EventNotifier extends BaseNotifierWithNetworkChecker<EventState> {
  Timer? _reservationTimer;
  StreamSubscription? _seatStatusSubscription;
  bool _isDisposed = false;
  bool _isProcessingPayment = false;

  @override
  EventState initialState() => const EventState(
      eventId: '',
      showId: '',
      customerId: '',
      isLoading: false,
      remainingTime: 600);

  void initializeWithParams({
    required final String eventId,
    required final String showId,
    required final String customerId,
  }) {
    // Sayfa her yüklendiğinde state'i sıfırla ve sayacı başlat
    state = EventState(
      eventId: eventId,
      showId: showId,
      customerId: customerId,
      isLoading: true,
      remainingTime: 600, // Sayaç burada 600'e ayarlanır
    );
    _loadInitialData();
  }

  @override
  void reloadData() => _loadInitialData();

  Future<void> _loadInitialData() async {
    _subscribeSeatStatus();
    // Event verisini (fiyat, tarih, stageId) yükle
    await loadEventsByIds([state.eventId]);
    // Veri yüklendikten sonra sayacı başlat
    _startReservationTimer();
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
              seatInfo['customerId'] == state.customerId)
            currentReservations.add(seatId);
        }

        // Fiyat 'state.seatPrice' getter'ı üzerinden okunuyor
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

  Future<void> loadEventsByIds(final List<String> eventIds) =>
      executeWithInternetCheck(
          () => ref.read(getEventsByIdsUseCaseProvider).call(eventIds),
          onSuccess: (final events) {
        if (_isDisposed) return;

        final mainEvent = events.firstWhere((final e) => e.id == state.eventId,
            orElse: () => events.first);

        //gerekirse bunları (örn: mainEvent.eventPrice) güncelleyin.

        final String? newEventPrice = mainEvent.price.toString();

        final Map<String, String> newEventDate = {
          'date': mainEvent.date ?? 'Tarih Bilgisi Yok',
        };

        final String? newStageId = mainEvent.stageId;

        state = state.copyWith(
          dataList: events,
          errorMessage: null,
          eventPrice: newEventPrice,
          eventDate: newEventDate,
          stageId: newStageId,
        );
      });

  void _startReservationTimer() {
    _reservationTimer?.cancel();
    _reservationTimer =
        Timer.periodic(const Duration(seconds: 1), (final timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      // Kalan süre 0 veya altındaysa (örneğin _handleTimeUp çalıştıysa)
      // timer'ı durdur ve çık.
      if (state.remainingTime <= 0) {
        timer.cancel();
        return;
      }

      final newTime = state.remainingTime - 1;
      state = state.copyWith(remainingTime: newTime);

      // Süre *tam o an* bittiyse, timer'ı durdur ve 'handle' fonksiyonunu çağır.
      if (newTime <= 0) {
        timer.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    cancelAllReservations(); // Önce rezervasyonları iptal et
    if (!_isDisposed) {
      // UI (ref.listen) bunu yakalayacak.
      // Sadece state'in geri kalanını temizle.
      state = state.copyWith(
        errorMessage: "Süreniz doldu. Rezervasyonlarınız iptal edildi.",
        selectedSeats: {},
        totalPrice: 0,
        firstReservationTime: null,
      );
    }
  }

  // --- DÜZELTME SONU ---

  Future<void> toggleSeatSelection(final String seatId) async {
    if (state.processingSeats.contains(seatId)) return;

    // Süre dolduysa işlem yapma
    if (state.isTimeUp) {
      _showTemporaryError("Süreniz doldu, işlem yapamazsınız.");
      return;
    }

    final isCurrentlySelected = state.selectedSeats.contains(seatId);

    if (isCurrentlySelected)
      await _removeSeat(seatId);
    else {
      final totalPendingAndSelected =
          state.selectedSeats.length + state.processingSeats.length;

      if (totalPendingAndSelected >= 3) {
        _showTemporaryError("En fazla 3 koltuk seçebilirsiniz.");
        return;
      }

      await _addSeat(seatId);
    }
  }

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

  Future<void> _removeSeat(final String seatId) async {
    if (_isDisposed) return;

    final newSelectedSeats = Set<String>.from(state.selectedSeats)
      ..remove(seatId);
    // 'state.seatPrice' getter'ı 'state.eventPrice' üzerinden doğru fiyatı alacak
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

  // CPU Optimizasyonu
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

  // Ödeme
  Future<void> processPayment(
    final String paymentMethod,
    final EventState paymentSnapshot,
  ) async {
    if (_isDisposed) return;

    // Süre dolduysa ödeme almayı engelle
    if (state.isTimeUp) {
      _showTemporaryError("Süreniz doldu, ödeme işlemi iptal edildi.");
      return;
    }

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
      await executeWithInternetCheck(() async {
        final confirmResult = await ref
            .read(confirmPurchaseUseCaseUseCaseProvider)
            .call(state.eventId, seatsToPurchase, state.customerId);

        if (confirmResult.isLeft()) return confirmResult;

        final ticket = _createTicket(paymentMethod, priceToPay);
        final ticketResult =
            await ref.read(createTicketUseCaseProvider).call(ticket);

        return ticketResult;
      }, onSuccess: (final _) {
        _reservationTimer?.cancel(); // Ödeme başarılıysa sayacı durdur
        if (!_isDisposed)
          state = state.copyWith(
            paymentSuccessful: true,
            isLoading: false,
            firstReservationTime: null,
            remainingTime: 0,
            // Süreyi bitir
            selectedSeats: {},
            totalPrice: 0,
          );
      });
    } catch (e) {
      if (!_isDisposed)
        _showTemporaryError("Ödeme sırasında beklenmedik bir hata oluştu.");
    } finally {
      if (!_isDisposed) state = state.copyWith(isLoading: false);
      _isProcessingPayment = false;
    }
  }

  // Bilet oluştur
  Ticket _createTicket(
    final String paymentMethod,
    final double totalPriceSnapshot,
  ) {
    final now = DateTime.now();
    String finalPrice;
    String finalMethod = paymentMethod;

    if (paymentMethod == 'free_ticket')
      finalPrice = "0.0";
    else if (paymentMethod.startsWith('coffee_') ||
        paymentMethod == 'free_coffee') {
      finalPrice =
          paymentMethod.split('_').last.replaceAll(RegExp(r'[^0-9]'), '');
      if (finalPrice.isEmpty) finalPrice = "20.0";
      finalMethod = 'coffee_donation';
    } else
      finalPrice = totalPriceSnapshot.toStringAsFixed(2);

    return Ticket(
      createdAt: now.toString(),
      updatedAt: now.toString(),
      id: '',
      showId: state.showId,
      customerId: state.customerId,
      stageId: state.stageId ?? '',
      eventId: state.eventId,
      orderPrice: finalPrice,
      orderMethod: finalMethod,
      buySeats:"",
      isPast: false,
    );
  }

  // Tüm rezervasyonları iptal et
  Future<void> cancelAllReservations() async {
    if (!state.hasSelectedSeats) return;

    final cancellationFutures = <Future<dynamic>>[];
    final seatsToCancel = Set<String>.from(state.selectedSeats);

    for (final seatId in seatsToCancel)
      cancellationFutures.add(ref
          .read(releaseReservationUseCaseProvider)
          .call(state.eventId, seatId, state.customerId));

    try {
      await Future.wait(cancellationFutures);
    } catch (e) {
      print("Tüm rezervasyonları iptal ederken hata oluştu: $e");
    }
  }

  // Geçici hata göster
  void _showTemporaryError(final String message) {
    if (_isDisposed) return;

    state = state.copyWith(errorMessage: message);
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed && state.errorMessage == message)
        state = state.copyWith(errorMessage: null);
    });
  }

  // Ödeme başarısını sıfırla
  void resetPaymentSuccess() {
    if (!_isDisposed) state = state.copyWith(paymentSuccessful: false);
  }

  // Temizle
  void cleanup() {
    _isDisposed = true;
    _reservationTimer?.cancel();
    _seatStatusSubscription?.cancel();
  }
}

// Helper Extentoins
extension EventNotifierX on WidgetRef {
  void initializeEventNotifier({
    required final String eventId,
    required final String showId,
    required final String customerId,
  }) {
    read(eventProvider.notifier).initializeWithParams(
      eventId: eventId,
      showId: showId,
      customerId: customerId,
    );
  }
}
