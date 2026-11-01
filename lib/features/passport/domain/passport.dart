/// Tiyatro Pasaportu çekirdeği: SAF mantık (Flutter/Firebase bağımlılığı yok).
/// Web karşılığı: site/js/pasaport-cekirdek.js — tanım ve test vektörleri
/// docs/PASAPORT.md'de; iki tarafın testi AYNI örnekleri doğrular.
/// Hiçbir şey sunucuya yazılmaz; her şey kullanıcının kendi biletlerinden
/// istemcide hesaplanır.
library;

/// Pasaport hesabının girdisi (bir bilet). Mobilde `DetailedTicket`'tan
/// türetilir (bkz. passport_page.dart).
class PassportTicket {
  final String id, eventId, showId, showName, stageId, stageName, posterUrl;

  /// Seans tarihi ham metni ("15.11.2026,22:00" ya da ISO).
  final String eventDate;

  /// Kapıda okutuldu zamanı (dolu = kapıdan geçti).
  final String usedAt;

  /// `pay_at_venue` | `paid` | `no_show` | `cancelled` | ''
  final String paymentStatus;
  final bool cancelled;

  const PassportTicket({
    required this.id,
    this.eventId = '',
    this.showId = '',
    this.showName = '',
    this.stageId = '',
    this.stageName = '',
    this.posterUrl = '',
    this.eventDate = '',
    this.usedAt = '',
    this.paymentStatus = '',
    this.cancelled = false,
  });
}

final RegExp _tr = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})(?:[,\s]+(\d{1,2}):(\d{2}))?$');

/// "15.11.2026,22:00" | "15.11.2026 22:00" | "15.11.2026" (gün sonu sayılır) |
/// ISO8601. Çözülemezse null.
DateTime? passportParseDate(final String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return null;
  final m = _tr.firstMatch(s);
  if (m != null) {
    final g = int.parse(m[1]!), a = int.parse(m[2]!), y = int.parse(m[3]!);
    final withTime = m[4] != null;
    final sa = withTime ? int.parse(m[4]!) : 23;
    final dk = withTime ? int.parse(m[5]!) : 59;
    if (sa > 23 || dk > 59) return null;
    final d = DateTime(y, a, g, sa, dk);
    // 31.02.2026 gibi taşan tarihleri reddet
    return d.year == y && d.month == a && d.day == g ? d : null;
  }
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) return null;
  return DateTime.tryParse(s)?.toLocal();
}

/// 'İZLENDİ' tanımı (tek kaynak):
/// - iptal ya da `no_show` -> izlenmedi
/// - `usedAt` dolu -> izlendi
/// - değilse seans tarihi ayrıştırılabilir VE [now]'dan önce -> izlendi
/// - ayrıştırılamayan tarih -> izlendi SAYILMAZ
bool passportWatched(final PassportTicket t, final DateTime now) {
  if (t.cancelled ||
      t.paymentStatus == 'cancelled' ||
      t.paymentStatus == 'no_show') {
    return false;
  }
  if (t.usedAt.trim().isNotEmpty) return true;
  final d = passportParseDate(t.eventDate);
  return d != null && d.isBefore(now);
}

class WatchedPlay {
  final String id, showKey, name, stageName, stageKey, posterUrl;
  final DateTime? date;
  const WatchedPlay({
    required this.id,
    required this.showKey,
    required this.name,
    required this.stageName,
    required this.stageKey,
    required this.posterUrl,
    required this.date,
  });
}

class StageStamp {
  final String key, name;
  final int count;
  final DateTime? first;
  const StageStamp(this.key, this.name, this.count, this.first);
}

class PassportBadge {
  final String id, title, how;
  final int current, target;
  const PassportBadge(this.id, this.title, this.how, this.current, this.target);
  bool get earned => current >= target;
}

class PassportSummary {
  final List<WatchedPlay> watched; // seans başına, yeniden eskiye
  final int playCount, stageCount, thisYear;
  final List<StageStamp> stamps;
  final List<PassportBadge> badges;
  const PassportSummary({
    required this.watched,
    required this.playCount,
    required this.stageCount,
    required this.thisYear,
    required this.stamps,
    required this.badges,
  });

  bool get isEmpty => watched.isEmpty;
  int get earnedBadges => badges.where((b) => b.earned).length;

  /// Paylaşım metni: kişisel veri (ad, telefon, e-posta) İÇERMEZ.
  String get shareText => isEmpty
      ? 'TiyatRol Tiyatro Pasaportum: ilk perdeyi bekliyorum.'
      : 'TiyatRol Tiyatro Pasaportum: $playCount oyun, $stageCount sahne, '
          'bu yıl $thisYear oyun, $earnedBadges rozet.';
}

String _key(final String s) => s.trim().toLowerCase();

PassportSummary buildPassport(
    final Iterable<PassportTicket> tickets, final DateTime now) {
  final seen = <String>{};
  final watched = <WatchedPlay>[];
  for (final t in tickets) {
    if (!passportWatched(t, now)) continue;
    final show = _key(t.showId).isNotEmpty ? _key(t.showId) : _key(t.showName);
    if (show.isEmpty) continue;
    final date = passportParseDate(t.eventDate) ?? passportParseDate(t.usedAt);
    // Aynı seans için birden çok bilet tek izleme sayılır
    final k = _key(t.eventId).isNotEmpty
        ? _key(t.eventId)
        : '$show|${date?.millisecondsSinceEpoch ?? t.id}';
    if (!seen.add(k)) continue;
    watched.add(WatchedPlay(
      id: t.id,
      showKey: show,
      name: t.showName.trim().isEmpty ? 'Tiyatro oyunu' : t.showName.trim(),
      stageName: t.stageName.trim(),
      stageKey:
          _key(t.stageId).isNotEmpty ? _key(t.stageId) : _key(t.stageName),
      posterUrl: t.posterUrl,
      date: date,
    ));
  }
  watched.sort((a, b) => (b.date?.millisecondsSinceEpoch ?? 0)
      .compareTo(a.date?.millisecondsSinceEpoch ?? 0));

  final plays = watched.map((w) => w.showKey).toSet();
  final thisYear = watched
      .where((w) => w.date != null && w.date!.year == now.year)
      .map((w) => w.showKey)
      .toSet()
      .length;

  final stageMap = <String, StageStamp>{};
  for (final w in watched) {
    if (w.stageKey.isEmpty) continue;
    final old = stageMap[w.stageKey];
    final first = (old?.first == null ||
            (w.date != null && w.date!.isBefore(old!.first!)))
        ? (w.date ?? old?.first)
        : old!.first;
    stageMap[w.stageKey] = StageStamp(
        w.stageKey,
        w.stageName.isNotEmpty ? w.stageName : (old?.name ?? 'Sahne'),
        (old?.count ?? 0) + 1,
        first);
  }
  final stamps = stageMap.values.toList()
    ..sort((a, b) =>
        b.count != a.count ? b.count.compareTo(a.count) : a.name.compareTo(b.name));
  final mostAtOneStage =
      stamps.fold<int>(0, (m, s) => s.count > m ? s.count : m);

  PassportBadge badge(final String id, final String title, final String how,
          final int cur, final int target) =>
      PassportBadge(id, title, how, cur > target ? target : cur, target);

  return PassportSummary(
    watched: watched,
    playCount: plays.length,
    stageCount: stamps.length,
    thisYear: thisYear,
    stamps: stamps,
    badges: [
      badge('ilk-perde', 'İlk perde',
          'Bir oyun izle (bileti kapıdan geçmiş ya da seansı geçmiş olsun).',
          plays.length, 1),
      badge('sahne-gezgini', '5 farklı sahne',
          '5 farklı sahnede oyun izle.', stamps.length, 5),
      badge('sadik-seyirci', 'Sadık seyirci',
          'Aynı sahnede 3 ayrı seans izle.', mostAtOneStage, 3),
      badge('sezon-yildizi', 'Sezon yıldızı',
          '${now.year} yılında 5 farklı oyun izle.', thisYear, 5),
      badge('on-perde', 'On perde', 'Toplam 10 farklı oyun izle.',
          plays.length, 10),
    ],
  );
}
