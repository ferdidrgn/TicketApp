import '../../../shows/domain/entities/show.dart';

/// Bir kategori için türetilmiş GERÇEK istatistik: kaç GERÇEK oyun bu
/// kategoride ve (vitrin kartı için) o kategorideki oyunlardan birinin
/// GERÇEK afişi.
class CategoryStat {
  final String category;
  final int count;
  final String sampleImageUrl;

  const CategoryStat({
    required this.category,
    required this.count,
    required this.sampleImageUrl,
  });
}

/// `shows` listesindeki GERÇEK `Show.category` alanlarından bir kategori
/// dağılımı çıkarır — sabit/uydurma bir kategori listesi DEĞİL. Kategorisi
/// boş olan oyunlar sayılmaz. En kalabalık kategori önce, eşitlikte
/// alfabetik sıralanır. Hem masaüstü (`DiscoveryCategoryShowcase`) hem
/// mobil (`discovery_page.dart`'taki `_MobileCategoryCard` şeridi) AYNI
/// bu fonksiyonu tüketir — kategori sayımı iki yerde ayrı ayrı YAZILMAZ.
List<CategoryStat> buildCategoryStats(final List<Show> shows) {
  final Map<String, List<Show>> byCategory = {};
  for (final show in shows) {
    final category = show.category.trim();
    if (category.isEmpty) continue;
    byCategory.putIfAbsent(category, () => []).add(show);
  }

  final stats = byCategory.entries
      .map((final entry) => CategoryStat(
            category: entry.key,
            count: entry.value.length,
            sampleImageUrl: entry.value.first.imageUrl,
          ))
      .toList()
    ..sort((final a, final b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.category.compareTo(b.category);
    });

  return stats;
}
