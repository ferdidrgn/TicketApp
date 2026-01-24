import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../events/domain/entities/event.dart';
import '../../../players/domain/entities/player.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../domain/entities/show.dart';
import 'show_provider.dart';

part 'show_detail_provider.g.dart';

/// Sayfanın ihtiyaç duyduğu tüm veriyi tutan sınıf
class ShowDetailState {
  final Show show;
  final List<Event> events;
  final List<Stage> stages;
  final List<Player> players;

  ShowDetailState({
    required this.show,
    required this.events,
    required this.stages,
    required this.players,
  });
}

/// 🔥 COMPOSITE PROVIDER (Tüm veriyi burada topluyoruz)
@riverpod
Future<ShowDetailState> showDetail(final Ref ref, final String showId) async {
  // 1. Önce Show verisini çek (Cache'de yoksa network'ten)
  // Not: showProvider'ın tekil getiren bir metodu yoksa, showsByIds kullanabiliriz.
  final shows = await ref.watch(showsByIdsProvider([showId]).future);
  if (shows.isEmpty) throw Exception('Gösteri bulunamadı');
  final show = shows.first;

  // 2. Event ID'leri hazırla
  final eventIds = show.eventsId.where((final e) => e.isNotEmpty).toList();

  // 3. Oyuncu ID'leri hazırla (Eski + Yeni kadro)
  final allPlayerIds = {...show.nowPlayersId, ...show.oldPlayersId}
      .where((final id) => id.isNotEmpty)
      .toList();

  // 4. 🔥 PARALEL VERİ ÇEKME (Events ve Players aynı anda başlasın)
  final results = await Future.wait([
    // Eventleri çek
    if (eventIds.isNotEmpty)
      ref.watch(eventsByIdsProvider(eventIds).future)
    else
      Future.value(<Event>[]),

    // Oyuncuları çek
    if (allPlayerIds.isNotEmpty)
      ref.watch(playersByIdsProvider(allPlayerIds).future)
    else
      Future.value(<Player>[]),
  ]);

  final events = results[0] as List<Event>;
  final players = results[1] as List<Player>;

  // 5. Stage ID'leri Eventlerden ayıkla ve çek
  final stageIds = events
      .map((final e) => e.stageId)
      .where((final id) => id.isNotEmpty && id != '0')
      .toSet()
      .toList();

  final stages = stageIds.isNotEmpty
      ? await ref.watch(stagesByIdsProvider(stageIds).future)
      : <Stage>[];

  // 6. Paketi teslim et
  return ShowDetailState(
    show: show,
    events: events,
    stages: stages,
    players: players,
  );
}
