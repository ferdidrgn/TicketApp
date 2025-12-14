import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/stages/presentation/providers/stage_notifier.dart';
import '../../data/repositories/stage_repository_provider.dart';
import '../../domain/usecases/get_search_stage_use_case_impl.dart';
import '../../domain/usecases/get_stage_by_id_use_case_impl.dart';
import '../../domain/usecases/get_stages_use_case_impl.dart';
import 'stage_state.dart';

final stageProvider =
    NotifierProvider.autoDispose<StageNotifier, StageState>(StageNotifier.new);

// Use case providers
final getStagesUseCaseProvider = Provider<GetStagesUseCase>(
    (final ref) => GetStagesUseCaseImpl(ref.watch(stageRepositoryProvider)));

final getStageByIdUseCaseProvider = Provider<GetStagesByIdsUseCase>(
    (final ref) => GetStageByIdUseCaseImpl(ref.watch(stageRepositoryProvider)));

final getSearchStageUseCaseProvider = Provider<GetSearchStageUseCase>(
    (final ref) =>
        GetSearchStageUseCaseImpl(ref.watch(stageRepositoryProvider)));
