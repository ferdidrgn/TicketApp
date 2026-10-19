import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../data/review_repository.dart';

// NOT: `@riverpod` codegen kullanılmaz (build_runner yok) — klasik API.

final reviewRepositoryProvider =
    Provider<ReviewRepository>((final ref) => ReviewRepository());

/// Bir oyunun yorumları (yeniden eskiye).
final reviewsByShowProvider =
    FutureProvider.family<List<Review>, String>((final ref, final showId) =>
        ref.watch(reviewRepositoryProvider).byShow(showId));

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

/// Kullanıcı bu oyunu izledi mi (tarihi geçmiş bileti var mı)? Sadece izleyen
/// yorum yazabilir.
final canReviewProvider =
    FutureProvider.family<bool, String>((final ref, final showId) async {
  final String? uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) return false;
  final tickets = await ref.watch(myTicketsProvider(uid).future);
  return tickets.past.any((final t) => t.ticket.showId == showId);
});

/// Yorum yazma/silme/gizleme sonrası ilgili listeleri tazeler.
void refreshReviews(final WidgetRef ref, final String showId) {
  ref.invalidate(reviewsByShowProvider(showId));
  ref.invalidate(reviewStatsProvider);
  ref.invalidate(reviewsByUserProvider);
}
