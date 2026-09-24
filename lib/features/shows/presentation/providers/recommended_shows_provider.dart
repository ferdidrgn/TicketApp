import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../../domain/entities/show.dart';
import 'show_provider.dart';

part 'recommended_shows_provider.g.dart';

// ==============================================================================
// GERÇEK, VERİYE DAYALI KİŞİSELLEŞTİRME — "Sana Özel"
// ==============================================================================
//
// Bir yapay zeka/ML modeli YOK, uydurma bir "popülerlik skoru" da yok.
// Sinyal tamamen GERÇEK: kullanıcının `User.favoriteShows`'u (favoriler) ve
// `myTicketsProvider`'dan gelen GERÇEK geçmiş bilet alımları. Bu iki
// kaynaktan gösterilerin gerçek `category`/`type` alanları toplanır, aynı
// kategori/türdeki (ve henüz favorilenmemiş/satın alınmamış) AKTİF
// gösteriler öne çıkarılır — basit ama dürüst bir içerik-tabanlı
// öneri. Kullanıcının hiç favorisi/bileti yoksa (yeni kullanıcı) GERÇEK
// bir sinyal olmadığından liste boş döner — UI bu durumda bölümü tamamen
// gizlemeli, sahte bir "senin için seçtik" listesi asla göstermemeli.

@riverpod
Future<List<Show>> recommendedShows(final Ref ref) async {
  final user = await ref.watch(userProfileProvider.future);
  if (user == null) return [];

  final tickets = await ref.watch(myTicketsProvider(user.id).future);
  final purchasedShowIds = tickets
      .map((final t) => t.ticket.showId)
      .where((final id) => id.isNotEmpty)
      .toSet();

  final interactedIds = {...user.favoriteShows, ...purchasedShowIds}
    ..removeWhere((final id) => id.isEmpty);
  if (interactedIds.isEmpty) return [];

  final interactedShows =
      await ref.watch(showsByIdsProvider(interactedIds.toList()).future);
  if (interactedShows.isEmpty) return [];

  final categoryCounts = <String, int>{};
  final typeCounts = <String, int>{};
  for (final show in interactedShows) {
    final category = show.category.trim();
    if (category.isNotEmpty) {
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    final type = show.type.trim();
    if (type.isNotEmpty) typeCounts[type] = (typeCounts[type] ?? 0) + 1;
  }
  if (categoryCounts.isEmpty && typeCounts.isEmpty) return [];

  final activeShows = await ref.watch(activeShowsProvider(false).future);

  final scored = activeShows
      .where((final show) => !interactedIds.contains(show.id))
      .map((final show) {
        final categoryScore = categoryCounts[show.category.trim()] ?? 0;
        final typeScore = typeCounts[show.type.trim()] ?? 0;
        return (show: show, score: categoryScore + typeScore);
      })
      .where((final entry) => entry.score > 0)
      .toList()
    ..sort((final a, final b) => b.score.compareTo(a.score));

  return scored.map((final entry) => entry.show).toList();
}
