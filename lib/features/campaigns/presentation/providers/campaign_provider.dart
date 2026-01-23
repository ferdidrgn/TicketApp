import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/campaign_repository_provider.dart';
import '../../domain/entities/campaign.dart';
import '../../domain/usecases/get_campaigns_use_case_impl.dart';

part 'campaign_provider.g.dart';

/// 1. UseCase Provider (Dependency Injection)
/// Fonksiyon ismi 'getCampaignsUseCase' -> Üretilen: 'getCampaignsUseCaseProvider'
@riverpod
GetCampaignsUseCase getCampaignsUseCase(final Ref ref) =>
    GetCampaignsUseCaseImpl(ref.watch(campaignRepositoryProvider));

/// 2. 🔥 KAMPANYA LİSTESİ (FutureProvider)
/// Fonksiyon ismi 'campaigns' -> Üretilen: 'campaignsProvider'
/// @riverpod default olarak 'autoDispose'dur.
@riverpod
Future<List<Campaign>> campaigns(final Ref ref) async =>
    ref.watch(getCampaignsUseCaseProvider).call().getOrThrow();
