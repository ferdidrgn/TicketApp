import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/date_formatter.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import 'home_show_filter_provider.dart';

// ==============================================================================
// ANA SAYFA — YAKLAŞAN SEANSLAR (gişe panosu)
// ==============================================================================
//
// Ana sayfanın "bilet dili" iki şeyi GERÇEK veriden gösterir: öne çıkan
// bilet (en yakın seans) ve gün gün yaklaşan seanslar. İkisi de bu tek
// provider'dan beslenir; oyun listesi ana sayfanın mevcut filtresinden
// (`homeShowsActiveFirstProvider(true)` — sadece izinli takımlar + harici
// biletli konuk oyunlar) gelir, yani ana sayfa filtresi burada da aynen
// geçerlidir.
//
// Neden widget içinde değil de provider'da: eski web hero'su
// `eventsByShowIdsProvider(candidateIds)` / `eventsByIdsProvider(...)`'ı
// `build()` içinde HER SEFERİNDE YENİ oluşturulan bir `List` ile çağırıyordu.
// Riverpod family argümanlarını `==` ile karşılaştırır, `List` ise kimlikle
// karşılaştırılır — her rebuild yeni bir provider örneği (ve yeni bir
// Firestore okuması) demekti. Provider gövdesinde bu listeler sadece üst
// provider değiştiğinde bir kez oluşturulur.
//
// `event_provider.dart` / `show_provider.dart` codegen (`.g.dart`) kullanıyor;
// bu sandbox'ta build_runner çalışmadığı için burada klasik `FutureProvider`.

/// Tek bir gerçek seans: oyun + etkinlik + ayrıştırılmış tarih + (bulunursa)
/// sahne.
class HomeSession {
  final Show show;
  final Event event;
  final DateTime date;
  final Stage? stage;

  const HomeSession({
    required this.show,
    required this.event,
    required this.date,
    this.stage,
  });

  /// Seansın günü (saat bilgisi atılmış) — gün şeridinde gruplama anahtarı.
  DateTime get day => DateTime(date.year, date.month, date.day);

  /// `Event.price` gerçek ve pozitif bir sayıysa "250 ₺" biçiminde, değilse
  /// `null` (fiyat uydurulmaz).
  String? get priceLabel {
    final double? p =
        double.tryParse(event.price.trim().replaceAll(',', '.'));
    if (p == null || p <= 0) return null;
    return p == p.roundToDouble()
        ? '${p.toInt()} ₺'
        : '${p.toStringAsFixed(2)} ₺';
  }
}

/// Ana sayfanın öne çıkan bileti: en yakın seansı olan oyun; hiç seans yoksa
/// (henüz programlanmamışsa) seanssız bir oyun — tarih UYDURULMAZ.
class HomeFeatured {
  final Show show;
  final HomeSession? session;

  const HomeFeatured({required this.show, this.session});
}

/// Öne çıkan bileti seçer: önce en yakın gerçek seans; yoksa biletleri başka
/// platformda satılan (her zaman "aktif" sayılan) ilk oyun; o da yoksa
/// listenin ilk oyunu (ana sayfa sıralaması: en yeni eklenen önce).
HomeFeatured? pickHomeFeatured(
    final List<HomeSession> sessions, final List<Show> shows) {
  if (sessions.isNotEmpty)
    return HomeFeatured(show: sessions.first.show, session: sessions.first);
  if (shows.isEmpty) return null;
  final external = shows.where((final s) => s.hasExternalTicketing);
  return HomeFeatured(
      show: external.isNotEmpty ? external.first : shows.first);
}

/// Ana sayfa oyunlarının GELECEK tarihli tüm seansları, en yakından uzağa.
///
/// Show↔Event ilişkisi iki yönde tutuluyor: `Event.showId` doluysa TEK
/// doğruluk kaynağı odur; `Show.eventsId` dizisi SADECE o alan boşsa yedek
/// (bkz. `show_provider.dart` → `_mergedEventsByShow`). Eski web hero'su
/// etkinlikleri doğrudan `event.showId` ile grupluyordu — `showId`'si boş,
/// sadece diziyle bağlı bir etkinlik "sıradaki oyun" hesabından sessizce
/// düşüyordu. Burada aynı kural uygulanıyor.
final homeUpcomingSessionsProvider =
    FutureProvider<List<HomeSession>>((final ref) async {
  final shows = await ref.watch(homeShowsActiveFirstProvider(true).future);
  if (shows.isEmpty) return const [];

  final showIds = shows.map((final s) => s.id).toList();
  final eventIdsFromArrays = shows
      .expand((final s) => s.eventsId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();

  final results = await Future.wait([
    ref.watch(eventsByShowIdsProvider(showIds).future),
    eventIdsFromArrays.isEmpty
        ? Future.value(<Event>[])
        : ref.watch(eventsByIdsProvider(eventIdsFromArrays).future),
  ]);

  // Sahne adı destekleyici bilgi: sahneler okunamazsa seanslar yine
  // gösterilir, sadece sahne alanı boş kalır.
  Map<String, Stage> stageById = const {};
  try {
    final stages = await ref.watch(stagesProvider(isLimit: false).future);
    stageById = {for (final st in stages) st.id: st};
  } catch (_) {}

  final eventsById = <String, Event>{
    for (final e in [...results[0], ...results[1]]) e.id: e,
  };
  final showById = {for (final s in shows) s.id: s};
  final ownersByEventId = <String, Set<String>>{};
  for (final show in shows) {
    for (final eventId in show.eventsId) {
      if (eventId.isEmpty) continue;
      ownersByEventId.putIfAbsent(eventId, () => {}).add(show.id);
    }
  }

  final now = DateTime.now();
  final sessions = <HomeSession>[];
  for (final event in eventsById.values) {
    final date = DateFormatter.parseDateString(event.date);
    if (date == null || !date.isAfter(now)) continue;
    final owners = event.showId.isNotEmpty
        ? {event.showId}
        : (ownersByEventId[event.id] ?? const <String>{});
    for (final showId in owners) {
      final show = showById[showId];
      if (show == null) continue;
      sessions.add(HomeSession(
        show: show,
        event: event,
        date: date,
        stage: stageById[event.stageId],
      ));
    }
  }
  sessions.sort((final a, final b) => a.date.compareTo(b.date));
  return sessions;
});
