import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../domain/entities/stage.dart';
import 'stage_provider.dart';

part 'stage_detail_provider.g.dart';

/// UI Model: Sahne ve o sahneye ait gösterileri bir arada tutar
class StageDetailState {
  final Stage stage;
  final List<Show> shows;

  const StageDetailState({required this.stage, required this.shows});
}

@riverpod
Future<StageDetailState> stageDetail(
    final Ref ref, final String stageId) async {
  final stages = await ref.watch(stagesByIdsProvider([stageId]).future);
  if (stages.isEmpty) throw Exception('Sahne bulunamadı');
  final stage = stages.first;

  final showIds = stage.showsId.where((final id) => id.isNotEmpty).toList();

  final shows = showIds.isNotEmpty
      ? await ref.watch(showsByIdsProvider(showIds).future)
      : <Show>[];

  return StageDetailState(stage: stage, shows: shows);
}
