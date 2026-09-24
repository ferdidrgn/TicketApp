import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../teams/presentation/providers/team_provider.dart';

// ==============================================================================
// ANA SAYFA — SADECE KENDİ TAKIMLARIMIZIN OYUNLARI
// ==============================================================================
//
// Kullanıcının kendi talebi (birebir): "anasayfada... tiyatrol takımı ve
// ataşehir tiyatro topluluğu ekiplerinin oyunu çıkması lazım. Başka
// dışarıdan aldığımız oyunlar ve o oyunların görselleri yer almaması
// lazım." Ana sayfa/landing, `showsActiveFirstProvider`/
// `activeShowsProvider`'ın TÜM Firestore kataloğunu (her takımın oyunu
// dahil — arama/keşfet sayfaları BİLEREK bunu kullanmaya devam ediyor,
// oralarda filtre YOK) göstermek yerine, artık SADECE bu iki takıma ait
// gösterileri gösteriyor. `show_provider.dart`'a (codegen `.g.dart`'ı var,
// bu sandbox'ta build_runner çalışmıyor) yeni bir `@riverpod` provider
// EKLEMİYORUZ — klasik `FutureProvider.family` API'siyle mevcut
// provider'ların üzerine ince bir filtre katmanı kuruyoruz.
//
// Takım eşleştirmesi isme göre (case-insensitive `contains`) yapılıyor —
// Firestore'da sabit/bilinen bir takım ID'si yok, ama takım isimleri
// biliniyor. Eşleşen takım bulunamazsa (ör. henüz Firestore'da o isimde
// bir Team dokümanı yoksa) sessizce BOŞ liste döner — asla "eşleşme
// bulunamadıysa hepsini göster"e düşmez, çünkü tam da göstermemesi
// istenen "dışarıdan alınan" oyunlar o zaman geri sızardı.
const List<String> _kHomeAllowedTeamNameFragments = [
  'tiyatrol',
  'ataşehir',
];

/// Ana sayfada gösterilmesine izin verilen takımların GERÇEK Firestore
/// ID'leri. `teamsProvider(isLimit: false)` — tam katalog, "son N takım"
/// sınırına takılmasın diye.
final homeAllowedTeamIdsProvider = FutureProvider<Set<String>>((final ref) async {
  final teams = await ref.watch(teamsProvider(isLimit: false).future);
  return teams
      .where((final team) {
        final name = team.name.toLowerCase();
        return _kHomeAllowedTeamNameFragments.any(name.contains);
      })
      .map((final team) => team.id)
      .toSet();
});

// Kendi takımlarımızın oyunlarının yanı sıra, biletleri harici bir
// platformda satılan "konuk" oyunlar da (bkz. `Show.externalTicketUrl`)
// ana sayfada gösterilir — bunlar hangi takıma ait olursa olsun, kartında
// "BAŞKA PLATFORMDA" rozetiyle işaretlenip o platforma yönlendirilirler.
// Kullanıcının kendi talebi: "herkes farklı ölür gibi oyunlar başka
// platformlarda... status ve link ekleyelim... o linke tıklayıp o siteden
// oyun etkinliklerini alsınlar."
List<Show> _filterToHomeTeams(
        final List<Show> shows, final Set<String> allowedTeamIds) =>
    shows
        .where((final show) =>
            allowedTeamIds.contains(show.teamId) || show.hasExternalTicketing)
        .toList();

// Kullanıcının kendi talebi (birebir): "en son yaratılan aktif oyunluğa
// göre filtrelemeler yap önce en yeniler ve aktfiler ekrana gelsin."
// Ana sayfa artık `showsActiveFirstProvider`in kendi "gerçek etkinliği
// olan aktif oyun önce, kalanlar eklenme tarihine göre" sıralamasını
// KULLANMIYOR — bunun yerine TÜMÜ (harici biletli dahil) tek bir listede
// gerçek `Show.createdAt`'a göre azalan sırada (en yeni en üstte)
// gösteriliyor. Harici biletli oyunların (bkz. `hasExternalTicketing`)
// bizim sistemimizde asla gerçek `Event` kaydı olmayacağı için eski
// mantıkla hep "aktif olmayan" sayılıp en dibe düşmesi bu isteğin asıl
// nedeni — ör. az önce eklenen "Herkes Farklı Ölür" en üstte görünmeli.
List<Show> _sortHomeShowsByRecency(final List<Show> shows) {
  final sorted = List<Show>.of(shows);
  sortShowsByCreatedAtDescending(sorted);
  return sorted;
}

/// `showsActiveFirstProvider`in ana sayfaya süzülmüş hâli — artık en son
/// eklenen oyun en üstte, sadece izinli takımların (+ harici biletli
/// konuk oyunların) gösterileri.
final homeShowsActiveFirstProvider =
    FutureProvider.family<List<Show>, bool>((final ref, final isLimit) async {
  final allowedTeamIds = await ref.watch(homeAllowedTeamIdsProvider.future);
  if (allowedTeamIds.isEmpty) return [];
  final shows =
      await ref.watch(showsActiveFirstProvider(isLimit).future);
  return _sortHomeShowsByRecency(_filterToHomeTeams(shows, allowedTeamIds));
});

/// `activeShowsProvider`ın ana sayfaya süzülmüş hâli — mobil ana
/// sayfanın "Aktif Oyunlar" şeridi bunu kullanır. Bu şerit ÖZELLİKLE
/// "takviminde gerçek yaklaşan etkinliği olan" oyunları anlatıyor, bu
/// yüzden kendi orijinal sıralamasını (en yakın etkinlik tarihine göre
/// artan) korur — harici biletli oyunlar zaten gerçek `Event` kaydı
/// olmadığından bu şeride hiç girmez, recency sıralaması burada
/// gerekmiyor.
final homeActiveShowsProvider =
    FutureProvider.family<List<Show>, bool>((final ref, final isLimit) async {
  final allowedTeamIds = await ref.watch(homeAllowedTeamIdsProvider.future);
  if (allowedTeamIds.isEmpty) return [];
  final shows = await ref.watch(activeShowsProvider(isLimit).future);
  return _filterToHomeTeams(shows, allowedTeamIds);
});
