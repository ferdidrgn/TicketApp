import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/domain/entities/event.dart';
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
    state = state.copyWith(
      eventId: eventId,
      showId: showId,
      customerId: customerId,
      isLoading: true,
      remainingTime: 600,
      dataList: state.dataList, // Önceki eventleri koru
    );
    _loadInitialData();
  }

  @override
  void reloadData() => _loadInitialData();

  Future<void> _loadInitialData() async {
    _subscribeSeatStatus();

    // --- KRİTİK DEĞİŞİKLİK 1: 'loadEventsByIds' KULLANILMAYACAK ---
    // 'loadEventsByIds' artık kümülatif liste içindir.
    // 'SeatSelectionScreen'in 'dataSingle'a ihtiyacı var.

    // Usecase'i doğrudan çağırıp 'dataSingle'ı ayarlayan yeni bir metot kullan:
    await executeWithInternetCheck(
        () => ref.read(getEventsByIdsUseCaseProvider).call([state.eventId]),
        onSuccess: (final events) => _setSingleEventLoaded(events));
    // --- DEĞİŞİKLİK SONU ---

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
            isLoading: false);
      },
      onError: (final e) {
        if (!_isDisposed)
          state = state.copyWith(errorMessage: e.toString(), isLoading: false);
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

  // Süre doldu
  void _handleTimeUp() {
    cancelAllReservations(); // Önce rezervasyonları iptal et
    if (!_isDisposed)
      state = state.copyWith(
        errorMessage: "Süreniz doldu. Rezervasyonlarınız iptal edildi.",
        selectedSeats: {},
        totalPrice: 0,
        firstReservationTime: null,
        remainingTime: 600, // Sayacı bir sonraki oturum için sıfırla
      );
  }

  /// BU METOT 'ShowDetailPage' İÇİN KULLANILIR VE KÜMÜLATİFTİR (LİSTEYE EKLER)
  Future<void> loadEventsByIds(final List<String> eventIds) async {
    // Güvenlik: Geçersiz ID'leri filtrele
    final validIds = eventIds
        .where((id) => id.trim().isNotEmpty && id != '0')
        .toSet()
        .toList();
    if (validIds.isEmpty) return;

    await executeWithInternetCheck(
      () => ref.read(getEventsByIdsUseCaseProvider).call(validIds),

      // --- KRİTİK DEĞİŞİKLİK 2: KÜMÜLATİF (ADDITIVE) onSuccess ---
      onSuccess: (final newEvents) {
        if (!ref.mounted || newEvents == null || newEvents.isEmpty) return;

        final currentList = state.dataList ?? <Event>[];
        final existingIds = currentList.map((e) => e.id).toSet();

        // Sadece state'te olmayan 'yeni' event'leri filtrele
        final uniqueNewEvents =
            newEvents.where((e) => !existingIds.contains(e.id));

        // State'i (Mevcut Liste + Benzersiz Yeni Liste) ile güncelle
        state = state.copyWith(dataList: [...currentList, ...uniqueNewEvents]);
      },
    );
  }

  // --- Koltuk seçimi, ekleme, çıkarma metotları (Değişiklik yok) ---
  Future<void> toggleSeatSelection(final String seatId) async {
    if (state.processingSeats.contains(seatId)) return;

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

  // Koltuk ekle
  Future<void> _addSeat(final String seatId) async {
    if (_isDisposed) return;

    state = state.copyWith(
      processingSeats: {...state.processingSeats, seatId},
      errorMessage: null,
    );

    await executeWithInternetCheck(
      () => ref
          .read(attemptReservationUseCaseProvider)
          .call(state.eventId, seatId, state.customerId),
      onSuccess: (final success) {
        try {
          if (!_isDisposed && !success)
            _showTemporaryError("Koltuk başkası tarafından seçildi.");
        } catch (e) {
          if (!_isDisposed)
            _showTemporaryError("Rezervasyon hatası: ${e.toString()}");
        } finally {
          if (!_isDisposed)
            state = state.copyWith(
                processingSeats: {...state.processingSeats}..remove(seatId));
        }
      },
    );
  }

  // Koltuk çıkar
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
        errorMessage: null);

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

  void _setSingleEventLoaded(final List<Event>? events) {
    if (_isDisposed || events == null || events.isEmpty) return;

    final singleEvent = events.first;

    // 'dataSingle'ı ayarla (SeatSelectionScreen'in UI'ı için)
    state = state.copyWith(
      dataSingle: singleEvent,
      errorMessage: null,
      // 'dataList'e burada DOKUNMA, kümülatif olarak aşağıda ekle
    );

    // 'dataList'i de (mevcut değilse) kümülatif olarak güncelle
    final currentList = state.dataList ?? <Event>[];
    final existingIds = currentList.map((e) => e.id).toSet();

    if (!existingIds.contains(singleEvent.id)) {
      state = state.copyWith(dataList: [...currentList, singleEvent]);
    }
  }

  /*
  void _setEventLoaded(List<Event>? events) {
  final mergedEvents = {...?state.dataList, ...?events}.toList();
  state = state.copyWith(
    dataList: mergedEvents,
    dataSingle: events?.length == 1 ? events!.first : state.dataSingle,
    errorMessage: null,
  );
}

  */

  // Geçici hata göster
  void _showTemporaryError(final String message) {
    if (_isDisposed) return;

    state = state.copyWith(errorMessage: message);
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed && state.errorMessage == message)
        state = state.copyWith(errorMessage: null);
    });
  }

  // Ödeme başarısını sıfırla
  void resetPaymentSuccess() {
    if (!_isDisposed) state = state.copyWith(paymentSuccessful: false);
  }

  void cleanup() {
    _isDisposed = true;
    _reservationTimer?.cancel();
    _seatStatusSubscription?.cancel();
  }
}

extension EventNotifierX on WidgetRef {
  void initializeEventNotifier({
    required final String eventId,
    required final String showId,
    required final String customerId,
  }) {
    read(eventProvider.notifier).initializeWithParams(
        eventId: eventId, showId: showId, customerId: customerId);
  }
}
