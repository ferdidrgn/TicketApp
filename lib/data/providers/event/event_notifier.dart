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

  // GÜNCELLENDİ: Seat status stream subscription (Akıllı Sayaç için)
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
                  reservationDate.isBefore(earliestTimestamp!)) {
                earliestTimestamp = reservationDate;
              }
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

  // GÜNCELLENDİ: Rezervasyon timer'ı (Akıllı Sayaç)
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

  // GÜNCELLENDİ: Süre dolduğunda (Akıllı Sayaç için)
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

  // GÜNCELLENDİ: Koltuk seçimi toggle (Hızlı basma / 3 limit sorunu için)
  Future<void> toggleSeatSelection(final String seatId) async {
    // 1. Koltuk zaten işlemdeyse, tekrar basmayı engelle
    if (state.processingSeats.contains(seatId)) return;

    // Stream'den gelen güncel duruma göre karar ver
    final bool isCurrentlySelected = state.selectedSeats.contains(seatId);

    if (isCurrentlySelected) {
      // Koltuk MAVİ (seçili), o halde KALDIRMAK istiyoruz
      await _removeSeat(seatId);
    } else {
      // Koltuk MAVİ DEĞİL (yani YEŞİL), o halde EKLEMEK istiyoruz

      // DÜZELTME: Sadece seçili olanları değil, işlemde olanları da say.
      final totalPendingAndSelected =
          state.selectedSeats.length + state.processingSeats.length;

      if (totalPendingAndSelected >= 3) {
        _showTemporaryError("En fazla 3 koltuk seçebilirsiniz.");
        return; // Fonksiyondan hemen çık
      }

      // Limit aşılmadıysa koltuğu eklemeyi dene
      await _addSeat(seatId);
    }
  }

  // GÜNCELLENDİ: Koltuk ekleme (Koltuk bazlı loading ve Either hatası için)
  Future<void> _addSeat(final String seatId) async {
    if (_isDisposed) return;

    try {
      // 1. Koltuğu "işlemde" olarak ayarla
      state = state.copyWith(
        processingSeats: {...state.processingSeats, seatId},
        errorMessage: null, // Hataları temizle
      );

      // 2. Ağ işlemini (useCase) çağır
      final result = await ref.read(attemptReservationUseCaseProvider).call(
            state.eventId,
            seatId,
            state.customerId,
          );

      // 3. 'Either' sonucunu 'fold' ile işle
      result.fold(
        // 3a. Başarısızlık (Failure) durumu (Sol taraf)
        (final failure) {
          if (!_isDisposed) {
            _showTemporaryError(failure.message);
          }
        },
        // 3b. Başarı (Success) durumu (Sağ taraf)
        (final success) {
          // Buradaki 'success' artık 'bool' tipindedir
          if (!_isDisposed && !success) {
            _showTemporaryError("Koltuk başkası tarafından seçildi.");
          }
          // 'success' true ise hiçbir şey yapmıyoruz.
          // Değişikliğin stream'den gelip UI'ı güncellemesini bekliyoruz.
        },
      );
    } catch (e) {
      if (!_isDisposed) {
        _showTemporaryError("Rezervasyon hatası: ${e.toString()}");
      }
    } finally {
      // 4. İşlem bittiğinde koltuğu "işlemde" listesinden çıkar
      if (!_isDisposed) {
        state = state.copyWith(
          processingSeats: {...state.processingSeats}..remove(seatId),
        );
      }
    }
  }

  // GÜNCELLENDİ: Koltuk çıkarma (Koltuk bazlı loading ve Either hatası için)
  Future<void> _removeSeat(final String seatId) async {
    if (_isDisposed) return;

    try {
      // 1. Koltuğu "işlemde" olarak ayarla
      state = state.copyWith(
        processingSeats: {...state.processingSeats, seatId},
        errorMessage: null, // Hataları temizle
      );

      // 2. Ağ işlemini çağır
      final result = await ref.read(releaseReservationUseCaseProvider).call(
            state.eventId,
            seatId,
            state.customerId,
          );

      // 3. 'Either' sonucunu işle (Sadece hata durumunu yakalamak için)
      result.fold(
        // 3a. Başarısızlık (Failure) durumu
        (final failure) {
          if (!_isDisposed) {
            _showTemporaryError(failure.message);
          }
        },
        // 3b. Başarı (Success) durumu
        (final _) {
          // Başarılıysa bir şey yapma, stream'in güncellemesini bekle.
        },
      );
    } catch (e) {
      if (!_isDisposed) {
        _showTemporaryError("İptal hatası: ${e.toString()}");
      }
    } finally {
      // 4. İşlem bittiğinde koltuğu "işlemde" listesinden çıkar
      if (!_isDisposed) {
        state = state.copyWith(
          processingSeats: {...state.processingSeats}..remove(seatId),
        );
      }
    }
  }

  // Ödeme işlemi (Burada global isLoading kullanılması DOĞRUDUR)
  Future<void> processPayment(final String paymentMethod) async {
    if (!state.hasSelectedSeats) return;

    state = state.copyWith(isLoading: true); // Global loading AÇ

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
            firstReservationTime: null,
            // Ödeme başarılı, sayacı sıfırla
            remainingTime: 600, // Sayacı sıfırla
          );
        }
      },
      // executeWithInternetCheck, 'isLoading: false' ve 'errorMessage'
      // ayarlarını hata durumunda otomatik yapar.
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
    final seatsToCancel = Set<String>.from(state.selectedSeats);

    for (final seatId in seatsToCancel) {
      cancellationFutures.add(
        ref.read(releaseReservationUseCaseProvider).call(
              state.eventId,
              seatId,
              state.customerId,
            ),
      );
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
      if (!_isDisposed && state.errorMessage == message) {
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
