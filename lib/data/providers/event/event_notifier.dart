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

  // Yeni: ödeme esnasında reentrancy önlemek için local lock
  bool _isProcessingPayment = false;

  // Yeni: tap throttle map -> aynı koltuka çok hızlı basmayı engellemek için
  final Map<String, DateTime> _lastTapTimes = {};

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
            final newSeatPrice = double.tryParse(newEventPrice ?? "0") ?? 0;
            final newTotalPrice = state.selectedSeats.length * newSeatPrice;

            state = state.copyWith(
              eventDate: details?['eventDate'] as Map<String, String>?,
              eventPrice: newEventPrice,
              stageId: details?['stageId'] as String?,
              totalPrice: newTotalPrice,
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

  //  Seat status stream subscription (Akıllı Sayaç için)
  void _subscribeSeatStatus() {
    _seatStatusSubscription?.cancel();

    final stream =
        ref.read(getEventSeatStatusStreamUseCaseProvider).call(state.eventId);

    _seatStatusSubscription = stream.listen(
      (final seatStatusMap) {
        if (_isDisposed) return; // Disposed ise işlem yapma

        // --- GÜNCELLENEN BÖLÜM ---
        final currentReservations = <String>{};
        DateTime? earliestTimestamp; // En eski zamanı bulmak için

        for (final entry in seatStatusMap.entries) {
          final seatId = entry.key;
          final seatInfo = entry.value;

          if (seatInfo != null &&
              seatInfo['status'] == 'reserved' &&
              seatInfo['customerId'] == state.customerId) {
            currentReservations.add(seatId);

            // En eski rezervasyon zamanını bul
            final reservedAt = seatInfo['reservedAt'] as Timestamp?;
            if (reservedAt != null) {
              final reservationDate = reservedAt.toDate();
              if (earliestTimestamp == null ||
                  reservationDate.isBefore(earliestTimestamp))
                earliestTimestamp = reservationDate;
            }
          }
        }

        final newTotalPrice = currentReservations.length * state.seatPrice;

        state = state.copyWith(
          seatStatus: seatStatusMap,
          selectedSeats: currentReservations,
          totalPrice: newTotalPrice,
          firstReservationTime: earliestTimestamp,
          // State'e kaydet
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

  //  Rezervasyon timer'ı (Akıllı Sayaç)
  void _startReservationTimer() {
    _reservationTimer?.cancel();
    _reservationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (final timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        int newRemainingTime;
        if (state.firstReservationTime != null) {
          // Bir rezervasyon varsa, o zamandan bu yana geçen süreyi hesapla
          final elapsedSeconds =
              DateTime.now().difference(state.firstReservationTime!).inSeconds;

          // Kalan süreyi 600 saniyeden (10dk) çıkararak bul
          newRemainingTime = 600 - elapsedSeconds;
        } else {
          // Hiç rezervasyon yoksa, sayaç 600'de kalsın
          newRemainingTime = 600;
        }

        // State'i yeni hesaplanan kalan süre ile güncelle
        state = state.copyWith(remainingTime: newRemainingTime);

        // Kalan süre 0 veya daha az ise süreyi bitir
        if (state.isTimeUp) {
          timer.cancel();
          _handleTimeUp();
        }
      },
    );
  }

  //  Süre dolduğunda (Akıllı Sayaç için)
  void _handleTimeUp() {
    cancelAllReservations(); // İptal işlemlerini başlat
    if (!_isDisposed) {
      state = state.copyWith(
        errorMessage: "Süreniz doldu. Rezervasyonlarınız iptal edildi.",
        selectedSeats: {},
        totalPrice: 0,
        firstReservationTime: null,
        // Rezervasyon sayacını sıfırla
        remainingTime: 600, // Sayacı UI'da 600'e ayarla
      );
    }
  }

  //  Koltuk seçimi toggle (Hızlı basma / 3 limit sorunu için)
  Future<void> toggleSeatSelection(final String seatId) async {
    if (_isDisposed) return;

    // Throttle: aynı koltuğa 300ms'den daha sık basmayı engelle
    final last = _lastTapTimes[seatId];
    final now = DateTime.now();
    if (last != null && now.difference(last).inMilliseconds < 300) return;
    _lastTapTimes[seatId] = now;

    // Eğer o koltuk zaten işlemdeyse, geri dön
    if (state.processingSeats.contains(seatId)) return;

    final bool isCurrentlySelected = state.selectedSeats.contains(seatId);

    if (isCurrentlySelected) {
      await _removeSeat(seatId);
    } else {
      final totalPendingAndSelected =
          state.selectedSeats.length + state.processingSeats.length;

      if (totalPendingAndSelected >= 3) {
        _showTemporaryError("En fazla 3 koltuk seçebilirsiniz.");
        return;
      }

      // ÖNEMLİ: burada optimistic update + backend çağrısı
      await _addSeat(seatId);
    }
  }

  //  Koltuk ekleme (Koltuk bazlı loading ve Either hatası için)
  Future<void> _addSeat(final String seatId) async {
    if (_isDisposed) return;

    // 0. optimistic: işlemde olarak ekle (UI spinner göstersin)
    state = state.copyWith(
      processingSeats: {...state.processingSeats, seatId},
      errorMessage: null,
    );

    try {
      // Ağ çağrısını yap: attemptReservationUseCaseProvider
      final result = await ref
          .read(attemptReservationUseCaseProvider)
          .call(state.eventId, seatId, state.customerId);

      result.fold(
        (final failure) {
          if (!_isDisposed) _showTemporaryError(failure.message);
        },
        (final success) {
          if (!_isDisposed && !success) {
            _showTemporaryError("Koltuk başkası tarafından seçildi.");
          } else {
            // başarı: stream güncellemesi beklenir (server seat status stream ile gönderir)
            // Eğer hızlı güncelleme istiyorsan burada selectedSeats'e ekleyebilirsin,
            // fakat stream authoritative olmalı: çakışma riskini azaltmak için beklemek daha güvenli.
          }
        },
      );
    } catch (e) {
      if (!_isDisposed)
        _showTemporaryError("Rezervasyon hatası: ${e.toString()}");
    } finally {
      if (!_isDisposed) {
        state = state.copyWith(
          processingSeats: {...state.processingSeats}..remove(seatId),
        );
      }
    }
  }

  // Koltuk çıkarma (Hibrit: İyimser + Yüklenme Geri Bildirimi)
  Future<void> _removeSeat(final String seatId) async {
    if (_isDisposed) return;

    // --- HİBRİT GÜNCELLEME ---
    // 1. Koltuğu 'selectedSeats' listesinden HEMEN çıkar.
    final newSelectedSeats = Set<String>.from(state.selectedSeats)
      ..remove(seatId);
    // 2. Fiyatı HEMEN yeniden hesapla.
    final newTotalPrice = newSelectedSeats.length * state.seatPrice;
    // 3. Koltuğu "işlemde" listesine HEMEN ekle (Geri bildirim için).
    final newProcessingSeats = {...state.processingSeats, seatId};

    // 4. UI'ı (state'i) HEMEN güncelle.
    // (Hem sepeti hem de 'processing' listesini aynı anda güncelliyoruz)
    state = state.copyWith(
      selectedSeats: newSelectedSeats,
      totalPrice: newTotalPrice,
      processingSeats: newProcessingSeats, // YENİ: Yüklenme göstergesi için
      errorMessage: null,
    );
    // --- HİBRİT GÜNCELLEME BİTTİ ---

    try {
      // 5. Şimdi ağ işlemini arka planda sessizce çağır.
      final result = await ref.read(releaseReservationUseCaseProvider).call(
            state.eventId,
            seatId,
            state.customerId,
          );

      // 6. Hata durumunu işle (Eğer çıkarma işlemi sunucuda başarısız olursa)
      result.fold(
        (final failure) {
          if (!_isDisposed) _showTemporaryError(failure.message);
          // Hata olursa, stream zaten state'i eski haline
          // (koltuk sepette) geri döndürecektir.
        },
        (final _) {}, // Başarılıysa bir şey yapma, state zaten güncellendi.
      );
    } catch (e) {
      if (!_isDisposed) _showTemporaryError("İptal hatası: ${e.toString()}");
    } finally {
      // 7. İşlem bittiğinde (başarılı veya başarısız) koltuğu
      //    "işlemde" listesinden çıkar.
      if (!_isDisposed)
        state = state.copyWith(
            processingSeats: {...state.processingSeats}..remove(seatId));
    }
  }

  //State'i "dondurarak" (snapshot) race condition açığını kapatır
  Future<void> processPayment(final String paymentMethod) async {
    if (_isDisposed) return;

    // Reentrancy guard
    if (_isProcessingPayment) {
      _showTemporaryError("Ödeme zaten işleniyor.");
      return;
    }
    _isProcessingPayment = true;

    // SNAPSHOT
    final seatsToPurchase = List<String>.from(state.selectedSeats);
    final double priceSnapshot = state.totalPrice;

    if (seatsToPurchase.isEmpty) {
      _showTemporaryError("Sepetiniz boş.");
      _isProcessingPayment = false;
      return;
    }

    state = state.copyWith(isLoading: true);

    await executeWithInternetCheck(
      () async {
        // 1. Satın alma işlemini (snapshot'ı kullanarak) onayla
        final confirmResult = await ref
            .read(confirmPurchaseUseCaseUseCaseProvider)
            .call(state.eventId, seatsToPurchase, state.customerId);

        if (confirmResult.isLeft()) return confirmResult;

        // Create ticket using snapshot price
        final ticket = _createTicket(paymentMethod, priceSnapshot);
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
    _isProcessingPayment = false;
  }

  // Bilet oluştur. Artık anlık fiyat bilgisini (snapshot) parametre olarak alıyor
  TicketModel _createTicket(
    final String paymentMethod,
    final double totalPriceSnapshot,
  ) {
    final now = DateTime.now();

    // Kahve ücretini veya ücretsiz durumu belirle
    String finalPrice;
    String finalMethod = paymentMethod;

    if (paymentMethod == 'free_ticket')
      finalPrice = "0.0";
    else if (paymentMethod.startsWith('coffee_')) {
      // "coffee_20" -> 20.0
      finalPrice = paymentMethod.split('_').last;
      finalMethod = 'coffee_donation'; // Yöntemi grupla
    } else
      finalPrice = totalPriceSnapshot.toStringAsFixed(2);
    // Artık state.totalPrice yerine snapshot'ı kullan

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

  // Tüm rezervasyonları iptal et
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
      // Hata olsa bile state'in sıfırlanması gerekir,
      // çünkü stream bir süre sonra bunu düzeltecektir.
    }
  }

  // Geçici hata mesajı göster (2 saniye sonra temizle)
  void _showTemporaryError(final String message) {
    if (_isDisposed) return;

    state = state.copyWith(errorMessage: message);
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed && state.errorMessage == message)
        state = state.copyWith(errorMessage: null);
    });
  }

  // Ödeme başarı flag'ini sıfırla
  void resetPaymentSuccess() {
    if (!_isDisposed) state = state.copyWith(paymentSuccessful: false);
  }

  // Cleanup
  void cleanup() {
    _isDisposed = true;
    _reservationTimer?.cancel();
    _seatStatusSubscription?.cancel();
  }
}

// Helper method to initialize with params (Değişiklik yok)
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
