/// Yönetim paneli "Genel bakış" (dashboard) verisi — `adminStats` callable'ının
/// (bkz. `functions/src/stats.js`) döndürdüğü JSON'un Flutter tarafı karşılığı.
/// Web admin paneli (`site/js/admin/dashboard.js`) ile AYNI veri kaynağı;
/// alan adları ve anlamları kasıtlı olarak oradakiyle birebir eşleşir.
library;

/// Cloud Functions sonucu çoğu zaman `Map<Object?, Object?>` olarak gelir
/// (JSON içinden gelen her nesne için) — bu yardımcılar hangi somut tipte
/// gelirse gelsin güvenle `num`/`String`/`Map`/`List`'e çevirir.
num _asNum(final dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}

int _asInt(final dynamic v) => _asNum(v).toInt();

double? _asDoubleOrNull(final dynamic v) =>
    v == null ? null : _asNum(v).toDouble();

String _asString(final dynamic v) => v?.toString() ?? '';

Map<String, dynamic> _asMap(final dynamic v) {
  if (v is Map) {
    return v.map((final k, final value) => MapEntry(k.toString(), value));
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(final dynamic v) => v is List ? v : const <dynamic>[];

/// KPI kartları — ay bazlı ve tüm-zamanlar sayaçları.
class AdminDashboardKpi {
  final int viewsMonth;
  final int showViewsMonth;
  final int reservationsMonth;
  final int reservationsTotal;
  final int freeTicketsMonth;
  final int freeTicketsTotal;
  final int cardTicketsTotal;
  final int ticketsActiveTotal;
  final int ticketsAllTime;
  final int upcomingSessions;
  final int activeShows;
  final int cancelled;
  final double? cancelRate;
  final int noShow;
  final double? noShowRate;
  final int checkedIn;
  final double? checkInRate;
  final double? conversion;

  const AdminDashboardKpi({
    required this.viewsMonth,
    required this.showViewsMonth,
    required this.reservationsMonth,
    required this.reservationsTotal,
    required this.freeTicketsMonth,
    required this.freeTicketsTotal,
    required this.cardTicketsTotal,
    required this.ticketsActiveTotal,
    required this.ticketsAllTime,
    required this.upcomingSessions,
    required this.activeShows,
    required this.cancelled,
    required this.cancelRate,
    required this.noShow,
    required this.noShowRate,
    required this.checkedIn,
    required this.checkInRate,
    required this.conversion,
  });

  factory AdminDashboardKpi.fromJson(final Map<String, dynamic> j) {
    final reservations = _asMap(j['reservations']);
    final freeTickets = _asMap(j['freeTickets']);
    final cardTickets = _asMap(j['cardTickets']);
    return AdminDashboardKpi(
      viewsMonth: _asInt(j['viewsMonth']),
      showViewsMonth: _asInt(j['showViewsMonth']),
      reservationsMonth: _asInt(reservations['month']),
      reservationsTotal: _asInt(reservations['total']),
      freeTicketsMonth: _asInt(freeTickets['month']),
      freeTicketsTotal: _asInt(freeTickets['total']),
      cardTicketsTotal: _asInt(cardTickets['total']),
      ticketsActiveTotal: _asInt(j['ticketsActiveTotal']),
      ticketsAllTime: _asInt(j['ticketsAllTime']),
      upcomingSessions: _asInt(j['upcomingSessions']),
      activeShows: _asInt(j['activeShows']),
      cancelled: _asInt(j['cancelled']),
      cancelRate: _asDoubleOrNull(j['cancelRate']),
      noShow: _asInt(j['noShow']),
      noShowRate: _asDoubleOrNull(j['noShowRate']),
      checkedIn: _asInt(j['checkedIn']),
      checkInRate: _asDoubleOrNull(j['checkInRate']),
      conversion: _asDoubleOrNull(j['conversion']),
    );
  }

  static const empty = AdminDashboardKpi(
    viewsMonth: 0,
    showViewsMonth: 0,
    reservationsMonth: 0,
    reservationsTotal: 0,
    freeTicketsMonth: 0,
    freeTicketsTotal: 0,
    cardTicketsTotal: 0,
    ticketsActiveTotal: 0,
    ticketsAllTime: 0,
    upcomingSessions: 0,
    activeShows: 0,
    cancelled: 0,
    cancelRate: null,
    noShow: 0,
    noShowRate: null,
    checkedIn: 0,
    checkInRate: null,
    conversion: null,
  );
}

/// Seçili ayın bir günündeki görüntülenme sayısı ('yyyy-MM-dd').
class AdminDashboardDailyView {
  final String day;
  final int views;

  const AdminDashboardDailyView({required this.day, required this.views});

  factory AdminDashboardDailyView.fromJson(final Map<String, dynamic> j) =>
      AdminDashboardDailyView(
        day: _asString(j['day']),
        views: _asInt(j['views']),
      );
}

/// 12 aylık trend içinde tek bir oyunun aylık görüntülenme serisi.
class AdminDashboardShowSeries {
  final String showId;
  final String name;
  final List<int> values;

  const AdminDashboardShowSeries({
    required this.showId,
    required this.name,
    required this.values,
  });

  factory AdminDashboardShowSeries.fromJson(final Map<String, dynamic> j) =>
      AdminDashboardShowSeries(
        showId: _asString(j['showId']),
        name: _asString(j['name']),
        values: _asList(j['values']).map(_asInt).toList(),
      );
}

/// 12 aylık görüntülenme trendi: toplam + en çok görüntülenen oyunlar.
class AdminDashboardTrend {
  final List<String> months;
  final List<int> total;
  final List<AdminDashboardShowSeries> shows;

  const AdminDashboardTrend({
    required this.months,
    required this.total,
    required this.shows,
  });

  factory AdminDashboardTrend.fromJson(final Map<String, dynamic> j) =>
      AdminDashboardTrend(
        months: _asList(j['months']).map(_asString).toList(),
        total: _asList(j['total']).map(_asInt).toList(),
        shows: _asList(j['shows'])
            .map((final s) => AdminDashboardShowSeries.fromJson(_asMap(s)))
            .toList(),
      );

  static const empty =
      AdminDashboardTrend(months: [], total: [], shows: []);
}

/// "Oyunlar" tablosu satırı — görüntülenme + bilet + doluluk bir arada.
class AdminDashboardTopShow {
  final String showId;
  final String name;
  final int views;
  final int tickets;
  final int ticketsMonth;
  final double? conversion;
  final int sessions;
  final int upcoming;
  final int seatsSold;
  final int seatsTotal;
  final double? occupancy;

  const AdminDashboardTopShow({
    required this.showId,
    required this.name,
    required this.views,
    required this.tickets,
    required this.ticketsMonth,
    required this.conversion,
    required this.sessions,
    required this.upcoming,
    required this.seatsSold,
    required this.seatsTotal,
    required this.occupancy,
  });

  factory AdminDashboardTopShow.fromJson(final Map<String, dynamic> j) =>
      AdminDashboardTopShow(
        showId: _asString(j['showId']),
        name: _asString(j['name']),
        views: _asInt(j['views']),
        tickets: _asInt(j['tickets']),
        ticketsMonth: _asInt(j['ticketsMonth']),
        conversion: _asDoubleOrNull(j['conversion']),
        sessions: _asInt(j['sessions']),
        upcoming: _asInt(j['upcoming']),
        seatsSold: _asInt(j['seatsSold']),
        seatsTotal: _asInt(j['seatsTotal']),
        occupancy: _asDoubleOrNull(j['occupancy']),
      );
}

/// "Öne çıkanlar" listelerindeki (oyuncu/sahne/topluluk) tek satır.
class AdminDashboardNamedView {
  final String id;
  final String name;
  final int views;

  const AdminDashboardNamedView({
    required this.id,
    required this.name,
    required this.views,
  });

  factory AdminDashboardNamedView.fromJson(final Map<String, dynamic> j) =>
      AdminDashboardNamedView(
        id: _asString(j['id']),
        name: _asString(j['name']),
        views: _asInt(j['views']),
      );
}

/// Yaklaşan (veya son 7 gün içindeki) bir seans — doluluk bilgisiyle.
class AdminDashboardUpcomingSession {
  final String eventId;
  final String showId;
  final String show;
  final String stageId;
  final String stage;
  final String date;
  final int? ms;
  final int seatsSold;
  final int seatsHeld;
  final int seatsTotal;
  final double? occupancy;

  const AdminDashboardUpcomingSession({
    required this.eventId,
    required this.showId,
    required this.show,
    required this.stageId,
    required this.stage,
    required this.date,
    required this.ms,
    required this.seatsSold,
    required this.seatsHeld,
    required this.seatsTotal,
    required this.occupancy,
  });

  factory AdminDashboardUpcomingSession.fromJson(
          final Map<String, dynamic> j) =>
      AdminDashboardUpcomingSession(
        eventId: _asString(j['eventId']),
        showId: _asString(j['showId']),
        show: _asString(j['show']),
        stageId: _asString(j['stageId']),
        stage: _asString(j['stage']),
        date: _asString(j['date']),
        ms: j['ms'] == null ? null : _asInt(j['ms']),
        seatsSold: _asInt(j['seatsSold']),
        seatsHeld: _asInt(j['seatsHeld']),
        seatsTotal: _asInt(j['seatsTotal']),
        occupancy: _asDoubleOrNull(j['occupancy']),
      );
}

/// Mekân (Stage) sıralaması satırı.
class AdminDashboardVenueRow {
  final String stageId;
  final String name;
  final int views;
  final int sessions;
  final int upcoming;
  final int seatsSold;
  final int seatsTotal;
  final double? occupancy;

  const AdminDashboardVenueRow({
    required this.stageId,
    required this.name,
    required this.views,
    required this.sessions,
    required this.upcoming,
    required this.seatsSold,
    required this.seatsTotal,
    required this.occupancy,
  });

  factory AdminDashboardVenueRow.fromJson(final Map<String, dynamic> j) =>
      AdminDashboardVenueRow(
        stageId: _asString(j['stageId']),
        name: _asString(j['name']),
        views: _asInt(j['views']),
        sessions: _asInt(j['sessions']),
        upcoming: _asInt(j['upcoming']),
        seatsSold: _asInt(j['seatsSold']),
        seatsTotal: _asInt(j['seatsTotal']),
        occupancy: _asDoubleOrNull(j['occupancy']),
      );
}

/// Sunucunun uyguladığı okuma sınırları (maliyet notu — kullanıcıya bilgi).
class AdminDashboardLimits {
  final int events;
  final int shows;
  final bool showRowsCapped;

  const AdminDashboardLimits({
    required this.events,
    required this.shows,
    required this.showRowsCapped,
  });

  factory AdminDashboardLimits.fromJson(final Map<String, dynamic> j) =>
      AdminDashboardLimits(
        events: _asInt(j['events']),
        shows: _asInt(j['shows']),
        showRowsCapped: j['showRowsCapped'] == true,
      );

  static const empty =
      AdminDashboardLimits(events: 0, shows: 0, showRowsCapped: false);
}

/// `adminStats` callable'ının tüm yanıtı — bu, "Genel bakış" sekmesinin tek
/// veri kaynağıdır.
class AdminDashboardStats {
  final int generatedAt;
  final String month;
  final AdminDashboardKpi kpi;
  final List<AdminDashboardDailyView> days;
  final AdminDashboardTrend trend;
  final List<AdminDashboardTopShow> topShows;
  final List<AdminDashboardNamedView> topPlayers;
  final List<AdminDashboardNamedView> topStages;
  final List<AdminDashboardNamedView> topTeams;
  final List<AdminDashboardUpcomingSession> sessions;
  final List<AdminDashboardVenueRow> venues;
  final AdminDashboardLimits limits;

  const AdminDashboardStats({
    required this.generatedAt,
    required this.month,
    required this.kpi,
    required this.days,
    required this.trend,
    required this.topShows,
    required this.topPlayers,
    required this.topStages,
    required this.topTeams,
    required this.sessions,
    required this.venues,
    required this.limits,
  });

  factory AdminDashboardStats.fromJson(final Map<String, dynamic> j) =>
      AdminDashboardStats(
        generatedAt: _asInt(j['generatedAt']),
        month: _asString(j['month']),
        kpi: AdminDashboardKpi.fromJson(_asMap(j['kpi'])),
        days: _asList(j['days'])
            .map((final d) => AdminDashboardDailyView.fromJson(_asMap(d)))
            .toList(),
        trend: AdminDashboardTrend.fromJson(_asMap(j['trend'])),
        topShows: _asList(j['topShows'])
            .map((final s) => AdminDashboardTopShow.fromJson(_asMap(s)))
            .toList(),
        topPlayers: _asList(j['topPlayers'])
            .map((final s) => AdminDashboardNamedView.fromJson(_asMap(s)))
            .toList(),
        topStages: _asList(j['topStages'])
            .map((final s) => AdminDashboardNamedView.fromJson(_asMap(s)))
            .toList(),
        topTeams: _asList(j['topTeams'])
            .map((final s) => AdminDashboardNamedView.fromJson(_asMap(s)))
            .toList(),
        sessions: _asList(j['sessions'])
            .map((final s) =>
                AdminDashboardUpcomingSession.fromJson(_asMap(s)))
            .toList(),
        venues: _asList(j['venues'])
            .map((final v) => AdminDashboardVenueRow.fromJson(_asMap(v)))
            .toList(),
        limits: AdminDashboardLimits.fromJson(_asMap(j['limits'])),
      );
}
