import '../../../../../core/util/date_formatter.dart';
import '../../../../events/domain/entities/event.dart';
import '../../../../players/domain/entities/player.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../domain/entities/show.dart';
import '../../providers/show_detail_provider.dart';

/// Oyun detay sayfasının (web + mobil) ekranda gösterdiği her şey, tek bir
/// yerde ve SADECE gerçek veriden türetilir (`showDetailProvider`).
///
/// - Seanslar: tarihi geçmiş seanslar satışa sunulmaz (önceden geçmiş bir
///   seansa da "Bilet al" ile koltuk seçimine gidilebiliyordu); tarihe göre
///   sıralanır. Tarihi okunamayan bir seans gizlenmez, listenin sonuna
///   gider (ham tarih metniyle).
/// - Fiyat: `Event.price` > 0 değilse gösterilmez (uydurma "₺0" yok).
/// - Kadro: `Show.nowPlayersId` / `oldPlayersId` sırasıyla.
class ShowDetailData {
  final Show show;
  final List<ShowSession> sessions;
  final List<Player> cast;
  final List<Player> pastCast;
  final List<Stage> venues;

  const ShowDetailData({
    required this.show,
    required this.sessions,
    required this.cast,
    required this.pastCast,
    required this.venues,
  });

  factory ShowDetailData.from(final ShowDetailState state,
      {final DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final Map<String, Stage> stageById = {
      for (final s in state.stages) s.id: s,
    };

    final sessions = <ShowSession>[];
    for (final event in state.events) {
      final DateTime? when = DateFormatter.parseDateString(event.date.trim());
      if (when != null && when.isBefore(reference)) continue;
      final double? price =
          double.tryParse(event.price.trim().replaceAll(',', '.'));
      sessions.add(ShowSession(
        event: event,
        stage: stageById[event.stageId],
        when: when,
        price: price != null && price > 0 ? price : null,
      ));
    }
    sessions.sort((final a, final b) {
      if (a.when == null && b.when == null) return 0;
      if (a.when == null) return 1;
      if (b.when == null) return -1;
      return a.when!.compareTo(b.when!);
    });

    final Map<String, Player> playerById = {
      for (final p in state.players) p.id: p,
    };
    List<Player> pick(final Iterable<String> ids) => [
          for (final id in ids.where((final id) => id.isNotEmpty).toSet())
            if (playerById.containsKey(id)) playerById[id]!,
        ];
    final cast = pick(state.show.nowPlayersId);
    final Set<String> castIds = cast.map((final p) => p.id).toSet();
    final pastCast = pick(state.show.oldPlayersId)
        .where((final p) => !castIds.contains(p.id))
        .toList();

    final venues = <Stage>[];
    final seenStages = <String>{};
    for (final session in sessions) {
      final Stage? stage = session.stage;
      if (stage == null || stage.id.isEmpty) continue;
      if (seenStages.add(stage.id)) venues.add(stage);
    }

    return ShowDetailData(
      show: state.show,
      sessions: sessions,
      cast: cast,
      pastCast: pastCast,
      venues: venues,
    );
  }

  bool get isExternal => show.hasExternalTicketing;

  ShowSession? get nextSession => sessions.isEmpty ? null : sessions.first;

  double? get lowestPrice {
    double? lowest;
    for (final s in sessions) {
      final double? p = s.price;
      if (p != null && (lowest == null || p < lowest)) lowest = p;
    }
    return lowest;
  }

  /// Biletin üst şeridindeki tür: kategori, yoksa tür, o da yoksa "OYUN".
  String get kindLabel {
    final String category = show.category.trim();
    if (category.isNotEmpty) return trUpper(category);
    final String type = show.type.trim();
    return type.isNotEmpty ? trUpper(type) : 'OYUN';
  }

  /// Bilet alanı olarak basılacak "TÜR" — kategoriyle aynıysa ya da
  /// kategori boşsa (şeritte zaten yazıyor) tekrar edilmez.
  String get typeField {
    final String category = show.category.trim();
    final String type = show.type.trim();
    if (category.isEmpty || type.isEmpty) return '';
    return type.toLowerCase() == category.toLowerCase() ? '' : type;
  }

  String get description => show.description.replaceAll('\\n', '\n').trim();

  /// Gerçek gösteri kimliğinden türetilen seri numarası (barkod altı).
  String get serial {
    final String id = show.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return 'No. ${(id.length > 8 ? id.substring(0, 8) : id).toUpperCase()}';
  }
}

/// Satıştaki tek bir seans (Event) + sahnesi.
class ShowSession {
  final Event event;
  final Stage? stage;
  final DateTime? when;
  final double? price;

  const ShowSession({
    required this.event,
    required this.stage,
    required this.when,
    required this.price,
  });

  String get venueName => (stage?.name ?? '').trim();

  String? get priceLabel => price == null ? null : formatTicketPrice(price!);

  /// "12 Ekim, 20:30" — tarihi okunamıyorsa ham metin.
  String get shortLabel {
    final DateTime? d = when;
    if (d == null) return event.date.trim();
    return '${d.day} ${trMonths[d.month - 1]}, ${hhmm(d)}';
  }

  /// Ekran okuyucu için tam cümle.
  String get semanticLabel => [
        if (when != null)
          '${when!.day} ${trMonths[when!.month - 1]} '
              '${trWeekdays[when!.weekday - 1]}, saat ${hhmm(when!)}'
        else
          event.date.trim(),
        if (venueName.isNotEmpty) venueName,
        if (priceLabel != null) priceLabel!,
        'koltuk seç',
      ].join(', ');
}

const List<String> trMonths = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

const List<String> trWeekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

const List<String> trMonthsShort = [
  'OCA',
  'ŞUB',
  'MAR',
  'NİS',
  'MAY',
  'HAZ',
  'TEM',
  'AĞU',
  'EYL',
  'EKİ',
  'KAS',
  'ARA',
];

const List<String> trWeekdaysShort = [
  'PZT',
  'SAL',
  'ÇAR',
  'PER',
  'CUM',
  'CMT',
  'PAZ',
];

String hhmm(final DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String formatTicketPrice(final double value) => value == value.roundToDouble()
    ? '₺${value.toStringAsFixed(0)}'
    : '₺${value.toStringAsFixed(2).replaceAll('.', ',')}';

/// Türkçe büyük harf ("komedi" → "KOMEDİ", "ışık" → "IŞIK").
String trUpper(final String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
