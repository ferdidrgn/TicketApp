import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../events/data/repositories/event_repository_provider.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/domain/usecases/get_events_by_show_ids_use_case_impl.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../data/repositories/show_repository_provider.dart';
import '../../domain/entities/show.dart';
import '../../domain/usecases/add_show_use_case_impl.dart';
import '../../domain/usecases/delete_show_use_case_impl.dart';
import '../../domain/usecases/get_search_show_use_case_impl.dart';
import '../../domain/usecases/get_shows_by_ids_use_case_impl.dart';
import '../../domain/usecases/get_shows_use_case_impl.dart';
import '../../domain/usecases/update_show_use_case_impl.dart';

part 'show_provider.g.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS (Dependency Injection)
// ==============================================================================

@riverpod
AddShowUseCase addShowUseCase(final Ref ref) =>
    AddShowUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
DeleteShowUseCase deleteShowUseCase(final Ref ref) =>
    DeleteShowUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
UpdateShowUseCase updateShowUseCase(final Ref ref) =>
    UpdateShowUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
GetShowsUseCase getShowsUseCase(final Ref ref) =>
    GetShowsUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
GetShowsByIdsUseCase getShowsByIdsUseCase(final Ref ref) =>
    GetShowsByIdsUseCaseImpl(ref.watch(showRepositoryProvider));

@riverpod
GetSearchShowUseCase getSearchShowUseCase(final Ref ref) =>
    GetSearchShowUseCaseImpl(ref.watch(showRepositoryProvider));

// ==============================================================================
// 2. DATA PROVIDERS (READ ONLY)
// ==============================================================================

/// 🔥 TÜM GÖSTERİLERİ ÇEKER
/// Parametre: isLimit (bool)
/// Kullanım: ref.watch(showsProvider(true))
@riverpod
Future<List<Show>> shows(final Ref ref, {required final bool isLimit}) async =>
    ref.watch(getShowsUseCaseProvider).call(isLimit).getOrThrow();

/// 🔍 ARAMA SONUÇLARINI ÇEKER
/// Parametreler family olarak geçilir.
/// Kullanım: ref.watch(searchShowsProvider(categories: ['Tiyatro'], type: 'Dram'))
@riverpod
Future<List<Show>> searchShows(final Ref ref, final String? query,
        {required final List<String> categories, final String? type}) async =>
    ref.watch(getSearchShowUseCaseProvider).call(query, categories, type).getOrThrow();

/// 🆔 ID LİSTESİNE GÖRE ÇEKER
/// Kullanım: ref.watch(showsByIdsProvider(['id1', 'id2']))
@riverpod
Future<List<Show>> showsByIds(final Ref ref, final List<String> ids) async =>
    ref.watch(getShowsByIdsUseCaseProvider).call(ids).getOrThrow();

// ==============================================================================
// 3. TÜRETİLMİŞ (COMPUTED) PROVIDER'LAR — "AKTİF" OYUN KAVRAMI
// ==============================================================================
//
// Firestore'da "isActive" gibi elle tutulan bir alan YOK — kasıtlı olarak
// eklenmedi. Böyle bir bayrak, bir oyunun son etkinliği geçtiğinde birinin
// onu elle "false" yapmayı unutmasıyla kolayca gerçekle uyuşmaz hale gelir
// (ve senkron tutulması gereken ekstra bir yazma-yolu demektir). Onun
// yerine "aktiflik" mevcut `Show.eventsId` + `Event.date` alanlarından
// CANLI hesaplanıyor — `landing/app.js`'teki `upcomingEvents()` ile aynı
// mantık: bir oyunun takviminde bugünden sonraki en az bir etkinliği varsa
// aktiftir; hepsi geçmişte kaldıysa ya da hiç etkinliği yoksa değildir.
//
// Bu iki provider `@riverpod` kod üretimi KULLANMIYOR (bilerek) — bu
// sandbox'ta `build_runner` çalıştırılamıyor, `showsProvider`/`shows...`
// gibi diğerleri gibi otomatik bir `.g.dart` parçası gerektirseydi elle
// güncellenmiş sahte bir generated dosya yazmak riskli olurdu. Klasik
// `FutureProvider.family` API'si (flutter_riverpod) ek kod üretimi
// gerektirmeden derlenir, bu yüzden burada onu kullanıyoruz. Kullanım
// şekli SADECE bu yüzden farklı: `activeShowsProvider(true)` (isim
// olmadan pozisyonel bool), `showsProvider(isLimit: true)` gibi değil.
//
// NOT: `isLimit: true` iken önce Firestore'dan en fazla 20 oyun çekilip
// SONRA aktiflik filtresi uygulanıyor (showsProvider'ın kendi limitini
// aynen kullanıyor) — yani "aktif 20 oyun" değil, "en yeni 20 oyunun
// aktif olanları" garantisi var. Ana sayfa/vitrin gibi "son eklenenler"
// bağlamları için doğru davranış bu; sonucun 20'den az (hatta 0) olması
// olağan ve beklenen bir durumdur.

// `event_provider.dart` `@riverpod` kod üretimi kullanıyor — bu sandbox'ta
// `build_runner` çalıştırılamadığı için oraya yeni bir provider EKLEMEK
// mümkün değil (yeni bir `.g.dart` parçası gerektirir). Bu yüzden, tıpkı
// yukarıdaki `activeShowsProvider`/`pastShowsProvider` gibi, klasik
// `Provider`/`FutureProvider.family` API'sini burada kullanıyoruz.
final _getEventsByShowIdsUseCaseProvider =
    Provider<GetEventsByShowIdsUseCase>((final ref) =>
        GetEventsByShowIdsUseCaseImpl(ref.watch(eventRepositoryProvider)));

/// Etkinlikleri `Event.showId` alanı üzerinden DOĞRUDAN çeker — bir
/// gösterinin `eventsId` dizisine bağımlı değildir.
final eventsByShowIdsProvider =
    FutureProvider.family<List<Event>, List<String>>(
        (final ref, final showIds) async {
  if (showIds.isEmpty) return [];
  return ref
      .watch(_getEventsByShowIdsUseCaseProvider)
      .call(showIds)
      .getOrThrow();
});

// Bir Show <-> Event ilişkisi bu veri tabanında İKİ YÖNLÜ ve BİRBİRİNDEN
// BAĞIMSIZ tutuluyor: `Show.eventsId` (gösterinin kendi etkinlik ID
// listesi) ve `Event.showId` (etkinliğin kendi gösteri referansı). Normal
// şartlarda ikisi de aynı ilişkiyi anlatır, ama biri diğeriyle senkron
// kalacak diye garanti YOK — özellikle Firebase Console'dan elle eklenen
// bir kayıtta ikisinden sadece biri doldurulmuş olabilir. Önceden burada
// SADECE `Show.eventsId` kullanılıyordu; `Event.showId` boş/eksik kalan
// bir etkinlik (ya da tam tersi, sadece `Event.showId` dolu olan) hem
// "aktif oyun" hesabından hem de gösteri detay takviminden SESSİZCE
// kayboluyordu — gerçek, tarihi geçmemiş bir etkinlik varken ana
// sayfa/keşfet bomboş görünüyordu. Artık HER İKİ yön de birleştiriliyor;
// bir etkinlik iki yoldan BİRİYLE bile bağlıysa yakalanır.
Future<Set<String>> _activeShowIdsFromEvents(
    final Ref ref, final List<Show> shows) async {
  final showIds = shows.map((final s) => s.id).toList();
  if (showIds.isEmpty) return {};

  final eventIdsFromArrays = shows
      .expand((final s) => s.eventsId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();

  final results = await Future.wait([
    ref.watch(eventsByShowIdsProvider(showIds).future),
    eventIdsFromArrays.isNotEmpty
        ? ref.watch(eventsByIdsProvider(eventIdsFromArrays).future)
        : Future.value(<Event>[]),
  ]);

  // `event.id` -> event, iki sorgunun sonucunu tekilleştirerek birleştirir.
  final eventsById = <String, Event>{};
  for (final event in [...results[0], ...results[1]]) {
    eventsById[event.id] = event;
  }

  // `event.id` -> bu event'i `eventsId` dizisinde listeleyen gösteri(ler).
  final showIdsByEventId = <String, Set<String>>{};
  for (final show in shows) {
    for (final eventId in show.eventsId) {
      if (eventId.isEmpty) continue;
      showIdsByEventId.putIfAbsent(eventId, () => {}).add(show.id);
    }
  }

  final now = DateTime.now();
  final activeIds = <String>{};
  for (final event in eventsById.values) {
    final date = DateFormatter.parseDateString(event.date);
    if (date == null || !date.isAfter(now)) continue;
    // `event.showId` (etkinliğin kendi doğrudan referansı) VARSA tek
    // doğruluk kaynağı odur. `Show.eventsId` dizisi SADECE bu alan boşsa
    // yedek olarak kullanılır — aksi hâlde bir gösteri, başka bir
    // gösterinin ESKİ/senkron dışı kalmış `eventsId` referansı yüzünden
    // (etkinlik gerçekte başka bir gösteriye taşınmış olsa bile) yanlışlıkla
    // "bu etkinliğe sahip" görünebiliyordu.
    if (event.showId.isNotEmpty) {
      activeIds.add(event.showId);
    } else {
      final linkedShowIds = showIdsByEventId[event.id];
      if (linkedShowIds != null) activeIds.addAll(linkedShowIds);
    }
  }
  return activeIds;
}

/// 🟢 AKTİF OYUNLAR — takviminde en az bir gelecek etkinliği olanlar.
/// Sadece SAHNEDE OLANI göstermek gereken dar bağlamlar için (ör. arama
/// sayfasının "Etkinlikler" filtresi) — genel oyun listeleme/keşfet
/// ekranlarının VARSAYILANI artık bu DEĞİL, aşağıdaki
/// `showsActiveFirstProvider`: hiçbir oyunu tamamen gizlemeden aktifleri
/// öne alıyor. Kullanım: `ref.watch(activeShowsProvider(true))`
final activeShowsProvider =
    FutureProvider.family<List<Show>, bool>((final ref, final isLimit) async {
  final shows = await ref.watch(showsProvider(isLimit: isLimit).future);
  if (shows.isEmpty) return [];
  final activeIds = await _activeShowIdsFromEvents(ref, shows);
  return shows.where((final s) => activeIds.contains(s.id)).toList();
});

/// 🔴 GEÇMİŞ OYUNLAR — tüm etkinlikleri geçmişte kalmış (ya da hiç
/// etkinliği hiç olmamış) oyunlar. "Geçmiş Oyunlar" arşiv görünümü gibi
/// bir yer için — varsayılan listelerde KULLANILMAMALI.
/// Kullanım: `ref.watch(pastShowsProvider(false))`
final pastShowsProvider =
    FutureProvider.family<List<Show>, bool>((final ref, final isLimit) async {
  final shows = await ref.watch(showsProvider(isLimit: isLimit).future);
  if (shows.isEmpty) return [];
  final activeIds = await _activeShowIdsFromEvents(ref, shows);
  return shows.where((final s) => !activeIds.contains(s.id)).toList();
});

/// 🟢➡️🔴 TÜM OYUNLAR, AKTİF ÖNCE — genel oyun listeleme/keşfet
/// ekranlarının (ana sayfa, keşfet, arama'nın boş-sorgu göz atma hâli)
/// GERÇEK varsayılanı. Hiçbir oyun listeden tamamen düşürülmez — önce
/// takviminde gelecek etkinliği olan (aktif) oyunlar, ardından (varsa
/// yer kaldıysa) aktif olmayanlar gelir. `isLimit: true` iken
/// `showsProvider`ın kendi "en yeni N oyun" sınırı içinde aynı sıralama
/// uygulanır — yani aktif oyun sayısı az olduğunda liste boş görünmez,
/// geri kalanı aktif olmayan oyunlarla dolar.
/// Kullanım: `ref.watch(showsActiveFirstProvider(true))`
final showsActiveFirstProvider =
    FutureProvider.family<List<Show>, bool>((final ref, final isLimit) async {
  final shows = await ref.watch(showsProvider(isLimit: isLimit).future);
  if (shows.isEmpty) return [];
  final activeIds = await _activeShowIdsFromEvents(ref, shows);
  final active = <Show>[];
  final inactive = <Show>[];
  for (final show in shows)
    (activeIds.contains(show.id) ? active : inactive).add(show);
  return [...active, ...inactive];
});
