import 'dart:async';
import 'dart:math';
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

  // GEREKLİ: Ödeme esnasında reentrancy önlemek için local lock
  bool _isProcessingPayment = false;

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
    // 1. Stream'i hemen başlat (Akıllı sayaç mantığı burada)
    _subscribeSeatStatus();

    // 2. Statik event verilerini al
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
              isLoading: false,
            );
          },
        );
      }
    } catch (e) {
      if (!_isDisposed) state = state.copyWith(isLoading: false);
    }

    // 3. Timer'ı başlat ("Aptal" sayaç)
    _startReservationTimer();
  }

  // DÜZELTİLDİ: Seat status stream (Akıllı Sayaç + CPU Optimizasyonu)
  void _subscribeSeatStatus() {
    _seatStatusSubscription?.cancel();

    final stream =
        ref.read(getEventSeatStatusStreamUseCaseProvider).call(state.eventId);

    _seatStatusSubscription = stream.listen(
      (final seatStatusMap) {
        if (_isDisposed) return;

        final currentReservations = <String>{};
        DateTime? earliestTimestamp;

        for (final entry in seatStatusMap.entries) {
          final seatId = entry.key;
          final seatInfo = entry.value;

          if (seatInfo != null &&
              seatInfo['status'] == 'reserved' &&
              seatInfo['customerId'] == state.customerId) {
            currentReservations.add(seatId);

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

        // --- SAYAÇ HATASI DÜZELTMESİ (Akıllı Mantık) ---
        int newRemainingTime;
        if (earliestTimestamp != null) {
          // Eski rezervasyon bulundu, süreyi hesapla
          final elapsedSeconds =
              DateTime.now().difference(earliestTimestamp).inSeconds;

          // 10:25 hatası çözümü: Negatif süreyi engelle
          newRemainingTime = 600 - max(0, elapsedSeconds);
        } else {
          // Yeni oturum. Mevcut sayacı (belki 09:50'dedir) bozma.
          newRemainingTime = state.remainingTime;
        }
        // --- SAYAÇ DÜZELTMESİ BİTTİ ---

        // --- CPU OPTİMİZASYONU ---
        Map<String, List<String>> currentLayout = state.seatLayout;
        if (currentLayout.isEmpty ||
            state.seatStatus.keys.length != seatStatusMap.keys.length) {
          currentLayout = _groupSeatsFromStatus(
              seatStatusMap.cast<String, Map<String, dynamic>?>());
        }
        // --- OPTİMİZASYON BİTTİ ---

        state = state.copyWith(
          seatStatus: seatStatusMap,
          selectedSeats: currentReservations,
          totalPrice: newTotalPrice,
          firstReservationTime: earliestTimestamp,
          remainingTime: newRemainingTime,
          // Kalan süreyi buradan GÜNCELLE
          seatLayout: currentLayout,
          // Önbelleğe alınmış düzeni kaydet
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

  // DÜZELTİLDİ: Rezervasyon timer'ı ("Aptal" Geri Sayım)
  void _startReservationTimer() {
    _reservationTimer?.cancel();
    _reservationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (final timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        // Bu sayaç sadece state'deki mevcut süreyi 1 azaltır.
        final newRemainingTime = state.remainingTime - 1;

        state = state.copyWith(remainingTime: newRemainingTime);

        if (state.isTimeUp) {
          timer.cancel();
          _handleTimeUp();
        }
      },
    );
  }

  // Süre dolduğunda (Değişiklik yok)
  void _handleTimeUp() {
    cancelAllReservations();
    if (!_isDisposed) {
      state = state.copyWith(
        errorMessage: "Süreniz doldu. Rezervasyonlarınız iptal edildi.",
        selectedSeats: {},
        totalPrice: 0,
        firstReservationTime: null,
        remainingTime: 600,
      );
    }
  }

  // DÜZELTİLDİ: Koltuk seçimi toggle (Gereksiz 'throttle' kaldırıldı)
  Future<void> toggleSeatSelection(final String seatId) async {
    // 1. Koltuk zaten işlemdeyse (processing), tekrar basmayı engelle (En iyi kilit)
    if (state.processingSeats.contains(seatId)) return;

    // 2. Stream'den gelen güncel duruma göre karar ver
    final bool isCurrentlySelected = state.selectedSeats.contains(seatId);

    if (isCurrentlySelected) {
      // Koltuk MAVİ (seçili), o halde KALDIRMAK istiyoruz
      await _removeSeat(seatId);
    } else {
      // Koltuk MAVİ DEĞİL (yani YEŞİL), o halde EKLEMEK istiyoruz

      // 3. 3 koltuk limitini (işlemdekiler dahil) kontrol et
      final totalPendingAndSelected =
          state.selectedSeats.length + state.processingSeats.length;

      if (totalPendingAndSelected >= 3) {
        _showTemporaryError("En fazla 3 koltuk seçebilirsiniz.");
        return;
      }

      await _addSeat(seatId);
    }
  }

  // Koltuk ekleme (Pessimistic - Kötümser)
  Future<void> _addSeat(final String seatId) async {
    if (_isDisposed) return;

    try {
      // 1. Koltuğu "işlemde" olarak ayarla
      state = state.copyWith(
        processingSeats: {...state.processingSeats, seatId},
        errorMessage: null,
      );

      // 2. Ağ işlemini (useCase) çağır
      final result = await ref.read(attemptReservationUseCaseProvider).call(
            state.eventId,
            seatId,
            state.customerId,
          );

      // 3. Sonucu işle
      result.fold(
        (final failure) {
          if (!_isDisposed) _showTemporaryError(failure.message);
        },
        (final success) {
          if (!_isDisposed && !success) {
            _showTemporaryError("Koltuk başkası tarafından seçildi.");
          }
          // Başarılıysa stream'in güncellemesini bekle
        },
      );
    } catch (e) {
      if (!_isDisposed)
        _showTemporaryError("Rezervasyon hatası: ${e.toString()}");
    } finally {
      // 4. İşlem bittiğinde koltuğu "işlemde" listesinden çıkar
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

    // --- HİBRİT GÜNCELLEME (Anında UI + Geri Bildirim) ---
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
    // --- HİBRİT GÜNCELLEME BİTTİ ---

    try {
      // Arka planda sunucuya haber ver
      final result = await ref.read(releaseReservationUseCaseProvider).call(
            state.eventId,
            seatId,
            state.customerId,
          );

      result.fold(
        (final failure) {
          if (!_isDisposed) _showTemporaryError(failure.message);
          // Hata olursa stream state'i geri düzeltecek
        },
        (final _) {}, // Başarılıysa state zaten güncel
      );
    } catch (e) {
      if (!_isDisposed) _showTemporaryError("İptal hatası: ${e.toString()}");
    } finally {
      // İşlem bitince 'processing' listesinden çıkar
      if (!_isDisposed)
        state = state.copyWith(
            processingSeats: {...state.processingSeats}..remove(seatId));
    }
  }

  // CPU Optimizasyonu için Notifier'a taşınan yardımcı metot
  Map<String, List<String>> _groupSeatsFromStatus(
    final Map<String, Map<String, dynamic>?> seatStatus,
  ) {
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

  // DÜZELTİLDİ: Ödeme (Snapshot + Re-entrancy Kilidi)
  Future<void> processPayment(
    final String paymentMethod,
    final SeatSelectionState paymentSnapshot, // UI'dan gelen snapshot
  ) async {
    if (_isDisposed) return;

    // 1. Re-entrancy (yeniden girme) kilidi
    if (_isProcessingPayment) {
      _showTemporaryError("Ödeme zaten işleniyor.");
      return;
    }
    _isProcessingPayment = true; // Kilidi Kapat

    // 2. Snapshot'tan veriyi al (State'den değil)
    final seatsToPurchase = List<String>.from(paymentSnapshot.selectedSeats);
    final double priceToPay = paymentSnapshot.totalPrice;

    if (seatsToPurchase.isEmpty) {
      _showTemporaryError("Sepetiniz boş.");
      _isProcessingPayment = false; // Kilidi Aç
      return;
    }

    state = state.copyWith(isLoading: true); // Global yüklenmeyi başlat

    try {
      await executeWithInternetCheck(
        () async {
          // 3. Onaylama (Snapshot verisi ile)
          final confirmResult = await ref
              .read(confirmPurchaseUseCaseUseCaseProvider)
              .call(state.eventId, seatsToPurchase, state.customerId);

          if (confirmResult.isLeft()) return confirmResult;

          // 4. Bilet oluşturma (Snapshot verisi ile)
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
      // executeWithInternetCheck zaten hatayı işler, ama biz kilidi açmalıyız
      if (!_isDisposed) {
        _showTemporaryError("Ödeme sırasında beklenmedik bir hata oluştu.");
      }
    } finally {
      // 5. İşlem bittiğinde (başarılı ya da başarısız) kilidi AÇ
      _isProcessingPayment = false;
    }
  }

  // Bilet oluştur (Snapshot parametresi alır)
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
      if (finalPrice.isEmpty) finalPrice = "20.0"; // 'free_coffee' varsayılanı
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

  // Geçici hata mesajı göster (Değişiklik yok)
  void _showTemporaryError(final String message) {
    if (_isDisposed) return;

    state = state.copyWith(errorMessage: message);
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed && state.errorMessage == message)
        state = state.copyWith(errorMessage: null);
    });
  }

  // Ödeme başarı flag'ini sıfırla (Değişiklik yok)
  void resetPaymentSuccess() {
    if (!_isDisposed) state = state.copyWith(paymentSuccessful: false);
  }

  // Cleanup (Değişiklik yok)
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
