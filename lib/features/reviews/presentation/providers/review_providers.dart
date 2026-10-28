import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../../data/review_repository.dart';

// NOT: `@riverpod` codegen kullanılmaz (build_runner yok) — klasik API.

final reviewRepositoryProvider =
    Provider<ReviewRepository>((final ref) => ReviewRepository());

/// Bir oyunun yorumları (yeniden eskiye).
final reviewsByShowProvider =
    FutureProvider.family<List<Review>, String>((final ref, final showId) =>
        ref.watch(reviewRepositoryProvider).byShow(showId,
            uid: ref.watch(currentUserIdProvider)));

/// Engelledigim kullanicilar (yorumlari gizlenir).
final blockedUsersProvider = FutureProvider<Set<String>>((final ref) async {
  final String? uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) return <String>{};
  try {
    return await ref.watch(reviewRepositoryProvider).blockedIds(uid);
  } catch (_) {
    return <String>{};
  }
});

/// Bir kullanıcının yazdığı yorumlar (profil karnesi için).
final reviewsByUserProvider =
    FutureProvider.family<List<Review>, String>((final ref, final userId) =>
        ref.watch(reviewRepositoryProvider).byUser(userId));

/// showId → özet puan (kart rozetleri, "en çok beğenilenler").
final reviewStatsProvider =
    FutureProvider<Map<String, ReviewStat>>((final ref) async {
  try {
    final list = await ref.watch(reviewRepositoryProvider).recent();
    return ReviewStat.fromReviews(list);
  } catch (_) {
    // Yorum özelliği ek bilgidir: okunamazsa kartlar puansız kalır.
    return const {};
  }
});

/// Yorum hakki: SUNUCU karar verir (telefon dogrulamasi + o oyunun gecmis, gecerli bileti).
final reviewEligibilityProvider =
    FutureProvider.family<ReviewEligibility, String>((final ref, final showId) async {
  final String? uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    return const ReviewEligibility(false, 'NOT_VERIFIED_ATTENDEE', false);
  }
  try {
    return await ref.watch(reviewRepositoryProvider).canReview(showId);
  } catch (_) {
    return const ReviewEligibility(false, 'NOT_VERIFIED_ATTENDEE', false);
  }
});

final canReviewProvider = FutureProvider.family<bool, String>((final ref, final showId) async =>
    (await ref.watch(reviewEligibilityProvider(showId).future)).canReview);

/// Yorum yazma/silme/gizleme sonrası ilgili listeleri tazeler.
void refreshReviews(final WidgetRef ref, final String showId) {
  ref.invalidate(reviewsByShowProvider(showId));
  ref.invalidate(reviewStatsProvider);
  ref.invalidate(reviewsByUserProvider);
  ref.invalidate(reviewEligibilityProvider(showId));
  ref.invalidate(blockedUsersProvider);
}
