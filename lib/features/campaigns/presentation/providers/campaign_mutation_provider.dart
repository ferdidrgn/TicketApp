import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/campaign_repository_provider.dart';
import '../../domain/entities/campaign.dart';
import '../../domain/usecases/add_campaign_use_case_impl.dart';
import '../../domain/usecases/delete_campaign_use_case_impl.dart';
import '../../domain/usecases/update_campaign_use_case_impl.dart';
import 'campaign_provider.dart';

// 🔧 KODLAMA NOTU: `campaign_provider.dart` `@riverpod` codegen kullanıyor ve
// bir `campaign_provider.g.dart`'ı var — build_runner bu sandbox'ta
// çalışmadığından oraya yeni bir `@riverpod` provider EKLENEMEZ. Bu YENİ
// mutation provider'ı `team_mutation_provider.dart`/`event_mutation_
// provider.dart` ile AYNI, klasik/codegen'siz `Notifier`+`NotifierProvider`
// API'siyle ayrı bir dosyada tanımlandı.

final addCampaignUseCaseProvider = Provider<AddCampaignUseCase>((final ref) =>
    AddCampaignUseCaseImpl(ref.watch(campaignRepositoryProvider)));

final updateCampaignUseCaseProvider = Provider<UpdateCampaignUseCase>(
    (final ref) =>
        UpdateCampaignUseCaseImpl(ref.watch(campaignRepositoryProvider)));

final deleteCampaignUseCaseProvider = Provider<DeleteCampaignUseCase>(
    (final ref) =>
        DeleteCampaignUseCaseImpl(ref.watch(campaignRepositoryProvider)));

/// 🔥 YÖNETİM PANELİ İÇİN HAM KAMPANYA LİSTESİ.
///
/// Genel `campaignsProvider` (bkz. `campaign_provider.dart`) başlığı/görseli
/// boş yarım kayıtları kasıtlı olarak eler — vitrinde kırık kart göstermesin
/// diye. Admin panelinde tam tersi gerekir: taslak/yarım kampanyalar da
/// GÖRÜNÜP düzenlenebilmeli (diğer koleksiyonların admin sekmeleri de
/// `showsProvider`/`teamsProvider` gibi HAM listeyi kullanıyor — bkz.
/// `admin_shows_tab.dart`/`admin_teams_tab.dart`). Bu yüzden ayrı, süzgeçsiz
/// bir FutureProvider.
final adminCampaignsProvider = FutureProvider<List<Campaign>>((final ref) =>
    ref.watch(getCampaignsUseCaseProvider).call().getOrThrow());

final campaignMutationProvider =
    NotifierProvider<CampaignMutationNotifier, AsyncValue<void>>(
        CampaignMutationNotifier.new);

class CampaignMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// ➕ Admin panelinden yeni bir kampanya ekler.
  Future<void> addCampaign(
      final Campaign campaign, final File? imageFile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(addCampaignUseCaseProvider)
          .call(campaign, imageFile)
          .getOrThrow();
      ref.invalidate(adminCampaignsProvider);
      ref.invalidate(campaignsProvider);
    });
  }

  /// 🔄 Admin panelinden bir kampanyayı günceller.
  Future<void> updateCampaign({
    required final String campaignId,
    required final Map<String, dynamic> updatedData,
    final File? imageFile,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(updateCampaignUseCaseProvider)
          .call(campaignId, updatedData, imageFile)
          .getOrThrow();
      ref.invalidate(adminCampaignsProvider);
      ref.invalidate(campaignsProvider);
    });
  }

  /// 🗑️ Admin panelinden bir kampanyayı siler.
  Future<void> deleteCampaign(final String campaignId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(deleteCampaignUseCaseProvider)
          .call(campaignId)
          .getOrThrow();
      ref.invalidate(adminCampaignsProvider);
      ref.invalidate(campaignsProvider);
    });
  }
}
