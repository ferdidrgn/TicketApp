import 'dart:async';
import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/data/providers/event/event_provider.dart';
import 'package:ticketapp/data/providers/show/show_provider.dart';
import 'package:ticketapp/data/providers/stage/stage_provider.dart';
import 'package:ticketapp/domain/entities/event.dart';
import 'package:ticketapp/domain/entities/show.dart';
import 'package:ticketapp/domain/entities/stage.dart';
import 'package:ticketapp/domain/entities/ticket.dart';
import 'ticket_provider.dart';
import 'ticket_state.dart';

/// Bilet, Gösteri, Etkinlik ve Sahne verilerini birleştiren bir yardımcı sınıf (View Model).
class DetailedTicket {
  final Ticket ticket;
  final Show? show;
  final Event? event;
  final Stage? stage;
  final bool isPast;

  DetailedTicket({
    required this.ticket,
    this.show,
    this.event,
    this.stage,
    required this.isPast,
  });
}

class TicketNotifier extends BaseNotifierWithNetworkChecker<TicketState> {
  @override
  TicketState initialState() => const TicketState();

  @override
  void reloadData() {
    // Son yüklenen bilet listesi varsa, customerId'sini al ve yeniden yükle
    if (state.dataList != null && state.dataList!.isNotEmpty) {
      final customerId = state.dataList!.first.customerId;
      if (customerId.isNotEmpty && customerId != '0')
        loadTicketsAndDetailsByCustomerId(customerId);
    }
  }

  /// YENİ VE DOĞRU METOT:
  /// Belirli bir Müşteri ID'sine ait biletleri VE bu biletlerin tüm
  /// detay verilerini (Show, Event, Stage) yükleyip state'e yazar.
  Future<void> loadTicketsAndDetailsByCustomerId(
      final String customerId) async {
    if (customerId.isEmpty) {
      state = state.copyWith(dataList: [], isLoading: false);
      return;
    }

    // 1. Biletleri customerId ile yükle
    // Not: `executeWithInternetCheck` 'isLoading: true' ayarlar
    await executeWithInternetCheck(
      () => ref.read(getTicketByCustomerIdUseCaseProvider).call(customerId),
      onSuccess: (final tickets) async {
        // Bilet bulunamadıysa, state'i temizle ve bitir
        if (tickets.isEmpty) {
          state = state.copyWith(
            dataList: [],
            relatedShows: [],
            relatedEvents: [],
            relatedStages: [],
            isLoading: false,
            errorMessage: null, // Hata değil, boş liste
          );
          return;
        }

        // Bilet listesini state'e yaz (ancak hala yükleniyor, detaylar eksik)
        state = state.copyWith(
            dataList: tickets, errorMessage: null, isLoading: true);

        // 2. Biletlerden ID'leri topla
        final showIds = tickets.map((final t) => t.showId).toSet().toList();
        final eventIds = tickets.map((final t) => t.eventId).toSet().toList();
        final stageIds = tickets.map((final t) => t.stageId).toSet().toList();

        // 3. Detayları paralel olarak yükle
        try {
          // Diğer provider'ların use case'lerini ref.read ile okuyoruz
          final results = await Future.wait([
            ref.read(getShowsByIdsUseCaseProvider).call(showIds),
            ref.read(getEventsByIdsUseCaseProvider).call(eventIds),
            ref.read(getStageByIdUseCaseProvider).call(stageIds),
          ]);

          // Sonuçları işle (fold ile hata kontrolü)
          final List<Show>? shows =
              results[0].fold((final l) => [], (final r) => r as List<Show>);
          final List<Event>? events =
              results[1].fold((final l) => [], (final r) => r as List<Event>);
          final List<Stage>? stages =
              results[2].fold((final l) => [], (final r) => r as List<Stage>);

          // 4. Tüm detay verilerini state'e yaz
          state = state.copyWith(
            relatedShows: shows,
            relatedEvents: events,
            relatedStages: stages,
            isLoading: false, // Her şey bittiğinde yüklemeyi kapat
          );
        } catch (e) {
          setErrorState("Bilet detayları yüklenirken hata oluştu: $e");
        }
      },
      // executeWithInternetCheck'in 'onError' bloğu
      // Biletleri çekerken hata olursa burası çalışır
      // (BaseNotifierWithNetworkChecker'da zaten _setLoadingState(false) yapılır)
    );
  }

  /// Biletleri ID listesiyle ve detaylarıyla yükler (Eski metod)
  @Deprecated('Bunun yerine loadTicketsAndDetailsByCustomerId kullanın')
  Future<void> loadTicketsAndDetails(final List<String> ticketsIds) async {
    if (ticketsIds.isEmpty) return;
    await executeWithInternetCheck(
      () => ref.read(getTicketByIdUseCaseProvider).call(ticketsIds),
      onSuccess: (final tickets) {
        if (tickets.isNotEmpty) {
          // Biletleri ve detayları yükle (yeni metodumuzu çağırarak)
          loadTicketsAndDetailsByCustomerId(tickets.first.customerId);
        } else {
          state = state.copyWith(dataList: [], isLoading: false);
        }
      },
    );
  }

  // Orijinal createTicket metodu (değişiklik yok)
  Future<void> createTicket(final Ticket ticket) => executeWithInternetCheck(
          () => ref.read(createTicketUseCaseProvider).call(ticket),
          onSuccess: (final _) {
        if (state.dataList != null) {
          state = state.copyWith(dataList: [...state.dataList!, ticket]);
        }
      });
}
