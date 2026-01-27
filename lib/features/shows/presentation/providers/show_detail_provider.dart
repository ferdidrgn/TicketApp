import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
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
  final shows = await ref.watch(showsByIdsProvider([showId]).future);
  if (shows.isEmpty) throw Exception('Gösteri bulunamadı');
  final show = shows.first;

  // Filtreleme: Boş ID'leri temizle
  final eventIds = show.eventsId.where((final id) => id.isNotEmpty).toList();
  final nowPlayerIds =
      show.nowPlayersId.where((final id) => id.isNotEmpty).toList();
  final oldPlayerIds =
      show.oldPlayersId.where((final id) => id.isNotEmpty).toList();

  final allPlayerIds = {...nowPlayerIds, ...oldPlayerIds}.toList();

  final results = await Future.wait([
    if (eventIds.isNotEmpty)
      ref.watch(eventsByIdsProvider(eventIds).future)
    else
      Future.value(<Event>[]),
    if (allPlayerIds.isNotEmpty)
      ref.watch(playersByIdsProvider(allPlayerIds).future)
    else
      Future.value(<Player>[]),
  ]);

  final events = results[0] as List<Event>;
  final players = results[1] as List<Player>;

  // Sadece bu gösteriye ait ve geçerli sahnesi olan eventleri al
  final stageIds = events
      .map((final e) => e.stageId)
      .where((final id) => id.isNotEmpty)
      .toSet()
      .toList();

  final stages = stageIds.isNotEmpty
      ? await ref.watch(stagesByIdsProvider(stageIds).future)
      : <Stage>[];

  return ShowDetailState(
      show: show, events: events, stages: stages, players: players);
}
