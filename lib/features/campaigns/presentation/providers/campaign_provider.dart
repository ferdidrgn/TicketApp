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
///
/// Firestore'daki yarım/taslak bir kampanya kaydı (başlığı ve/veya görseli
/// boş bırakılmış) her tüketicide (ana sayfa web/mobil, promo banner,
/// kampanya vitrini) aynı kırık görünümü üretiyordu: boş, metinsiz, gri bir
/// "resim yüklenemedi" kutusu. Böyle eksik kayıtlar burada, TEK bir yerde,
/// listeden çıkarılıyor — sahte bir başlık/görsel uydurulmuyor, sadece
/// gösterilecek kadar tam olmayan kayıt sessizce düşürülüyor.
@riverpod
Future<List<Campaign>> campaigns(final Ref ref) async {
  final campaigns = await ref.watch(getCampaignsUseCaseProvider).call().getOrThrow();
  return campaigns
      .where((final c) => c.title.trim().isNotEmpty && c.imageUrl.trim().isNotEmpty)
      .toList();
}
