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

  // ------------------ Initialize ------------------
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
    );
    _loadInitialData();
  }

  @override
  void reloadData() => _loadInitialData();

  // ------------------ Load Events ------------------
  Future<void> _loadInitialData() async {
    _subscribeSeatStatus();

    await executeWithInternetCheck(
        () => ref.read(getEventsByIdsUseCaseProvider).call([state.eventId]),
        onSuccess: _setSingleEventLoaded);

    _startReservationTimer();
  }

  void _setSingleEventLoaded(final List<Event>? events) {
    if (_isDisposed || events == null || events.isEmpty) return;

    final singleEvent = events.first;

    // Update dataSingle for current UI
    state = state.copyWith(dataSingle: singleEvent, errorMessage: null);

    // Merge with existing dataList
    final currentList = state.dataList ?? [];
    if (!currentList.any((final e) => e.id == singleEvent.id))
      state = state.copyWith(dataList: [...currentList, singleEvent]);
  }

  Future<void> loadEventsByIds(final List<String> eventIds) async {
    final validIds = eventIds
        .where((final id) => id.trim().isNotEmpty && id != '0')
        .toSet()
        .toList();
    if (validIds.isEmpty) return;

    await executeWithInternetCheck(
      () => ref.read(getEventsByIdsUseCaseProvider).call(validIds),
      onSuccess: (final newEvents) {
        if (_isDisposed || newEvents == null || newEvents.isEmpty) return;

        final currentList = state.dataList ?? [];
        final existingIds = currentList.map((final e) => e.id).toSet();
        final uniqueNewEvents =
            newEvents.where((final e) => !existingIds.contains(e.id));

        state = state.copyWith(dataList: [...currentList, ...uniqueNewEvents]);
      },
    );
  }

  // ------------------ Seat Management ------------------
  void _subscribeSeatStatus() {
    _seatStatusSubscription?.cancel();

    final stream =
        ref.read(getEventSeatStatusStreamUseCaseProvider).call(state.eventId);
    _seatStatusSubscription = stream.listen(
      (final seatStatusMap) {
        if (_isDisposed) return;

        final currentReservations = <String>{};
        for (final entry in seatStatusMap.entries) {
          final seatInfo = entry.value;
          if (seatInfo?['status'] == 'reserved' &&
              seatInfo?['customerId'] == state.customerId)
            currentReservations.add(entry.key);
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
          state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      },
    );
  }

  Future<void> toggleSeatSelection(final String seatId) async {
    if (state.processingSeats.contains(seatId)) return;

    final isSelected = state.selectedSeats.contains(seatId);
    if (isSelected)
      await _removeSeat(seatId);
    else {
      if ((state.selectedSeats.length + state.processingSeats.length) >= 3) {
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
        errorMessage: null);

    await executeWithInternetCheck(
      () => ref
          .read(attemptReservationUseCaseProvider)
          .call(state.eventId, seatId, state.customerId),
      onSuccess: (final success) {
        if (!_isDisposed && !success)
          _showTemporaryError("Koltuk başkası tarafından seçildi.");
        state = state.copyWith(
            processingSeats: {...state.processingSeats}..remove(seatId));
      },
    );
  }

  Future<void> _removeSeat(final String seatId) async {
    if (_isDisposed) return;

    final newSelectedSeats = {...state.selectedSeats}..remove(seatId);
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
        (final failure) =>
            !_isDisposed ? _showTemporaryError(failure.message) : null,
        (final _) => null,
      );
    } catch (e) {
      if (!_isDisposed) _showTemporaryError("İptal hatası: $e");
    } finally {
      if (!_isDisposed)
        state = state.copyWith(
            processingSeats: {...state.processingSeats}..remove(seatId));
    }
  }

  Map<String, List<String>> _groupSeatsFromStatus(
      final Map<String, Map<String, dynamic>?> seatStatus) {
    final seatsByRow = <String, List<String>>{};
    for (final seatId in seatStatus.keys) {
      if (seatId.isEmpty) continue;
      seatsByRow.putIfAbsent(seatId[0], () => []).add(seatId);
    }

    final result = <String, List<String>>{};
    for (final row in seatsByRow.keys.toList()..sort()) {
      final seats = seatsByRow[row]!
        ..sort((final a, final b) => (int.tryParse(a.substring(1)) ?? 0)
            .compareTo(int.tryParse(b.substring(1)) ?? 0));
      result[row] = seats;
    }
    return result;
  }

  // ------------------ Timer ------------------
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

  void _handleTimeUp() {
    cancelAllReservations();
    if (!_isDisposed)
      state = state.copyWith(
        errorMessage: "Süreniz doldu. Rezervasyonlarınız iptal edildi.",
        selectedSeats: {},
        totalPrice: 0,
        firstReservationTime: null,
        remainingTime: 600,
      );
  }

  // ------------------ Payment ------------------
  Future<void> processPayment(
      final String paymentMethod, final EventState paymentSnapshot) async {
    if (_isDisposed || _isProcessingPayment) {
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
          return await ref.read(createTicketUseCaseProvider).call(ticket);
        },
        onSuccess: (final _) {
          _reservationTimer?.cancel();
          if (!_isDisposed)
            state = state.copyWith(
                paymentSuccessful: true,
                isLoading: false,
                firstReservationTime: null,
                remainingTime: 600);
        },
      );
    } catch (_) {
      if (!_isDisposed)
        _showTemporaryError("Ödeme sırasında beklenmedik bir hata oluştu.");
    } finally {
      _isProcessingPayment = false;
    }
  }

  Ticket _createTicket(
      final String paymentMethod, final double totalPriceSnapshot) {
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
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
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

    final cancellationFutures = state.selectedSeats.map(
      (final seatId) => ref
          .read(releaseReservationUseCaseProvider)
          .call(state.eventId, seatId, state.customerId),
    );

    try {
      await Future.wait(cancellationFutures);
    } catch (e) {
      print("Tüm rezervasyonları iptal ederken hata: $e");
    }
  }

  // ------------------ Helpers ------------------
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
