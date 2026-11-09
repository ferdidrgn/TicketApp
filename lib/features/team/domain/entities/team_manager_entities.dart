/// Ekip yöneticisi (TeamManager) mobil ekranının veri modelleri.
///
/// Bu modeller `functions/src/team.js`deki `getMyManagedTeams` /
/// `teamNotifyPreview` / `teamSendNotification` / `teamStats`
/// callable'larının döndürdüğü JSON'u birebir yansıtır — sunucu hangi
/// alanı döndürüyorsa yalnız o kullanılır, uydurma alan YOK. Kapsam
/// (hangi ekip/oyun/seans görünür) SUNUCUDA hesaplanır; bu ekran yalnız
/// sunucunun verdiği listeleri gösterir.
library;

int _asInt(final Object? v, [final int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? _asIntOrNull(final Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String _asString(final Object? v, [final String fallback = '']) =>
    v == null ? fallback : v.toString();

bool _asBool(final Object? v) => v == true;

/// Bir seans (Event) — ekip yöneticisinin kendi oyununun seansı.
class TeamManagerEvent {
  final String eventId;
  final int ms;
  final String dateText;
  final String stage;
  final int total;
  final int sold;
  final int held;

  /// Seansa ±24 saat kala mı (sahne kumandası şablonları yalnız bu
  /// pencerede kullanılabilir — bkz. `functions/src/config.js` NOTIFY.
  /// TIMED_WINDOW_MS).
  final bool inWindow;

  const TeamManagerEvent({
    required this.eventId,
    required this.ms,
    required this.dateText,
    required this.stage,
    required this.total,
    required this.sold,
    required this.held,
    required this.inWindow,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(ms);

  int get occupancyPercent => total > 0 ? ((sold / total) * 100).round() : 0;

  factory TeamManagerEvent.fromJson(final Map<dynamic, dynamic> json) =>
      TeamManagerEvent(
        eventId: _asString(json['eventId']),
        ms: _asInt(json['ms']),
        dateText: _asString(json['dateText']),
        stage: _asString(json['stage']),
        total: _asInt(json['total']),
        sold: _asInt(json['sold']),
        held: _asInt(json['held']),
        inWindow: _asBool(json['inWindow']),
      );
}

/// Ekip yöneticisinin kendi ekibine ait bir oyun (Show) ve yaklaşan
/// seansları.
class TeamManagerShow {
  final String showId;
  final String name;
  final List<TeamManagerEvent> events;

  const TeamManagerShow({
    required this.showId,
    required this.name,
    required this.events,
  });

  factory TeamManagerShow.fromJson(final Map<dynamic, dynamic> json) =>
      TeamManagerShow(
        showId: _asString(json['showId']),
        name: _asString(json['name']),
        events: ((json['events'] as List?) ?? const [])
            .map((final e) => TeamManagerEvent.fromJson(e as Map))
            .toList(),
      );
}

/// Kullanıcının AKTİF yönetici olduğu bir topluluk (Team).
class TeamManagerTeam {
  final String teamId;
  final String name;
  final List<TeamManagerShow> shows;

  const TeamManagerTeam({
    required this.teamId,
    required this.name,
    required this.shows,
  });

  factory TeamManagerTeam.fromJson(final Map<dynamic, dynamic> json) =>
      TeamManagerTeam(
        teamId: _asString(json['teamId']),
        name: _asString(json['name']),
        shows: ((json['shows'] as List?) ?? const [])
            .map((final e) => TeamManagerShow.fromJson(e as Map))
            .toList(),
      );
}

/// Bir bildirim şablonunun opsiyonel parametresi (ör. "kaç dakika sonra").
class NotifyTemplateParam {
  final String name;
  final List<int>? allowed;
  final int? min;
  final int? max;
  final int def;

  const NotifyTemplateParam({
    required this.name,
    this.allowed,
    this.min,
    this.max,
    required this.def,
  });

  factory NotifyTemplateParam.fromJson(final Map<dynamic, dynamic> json) =>
      NotifyTemplateParam(
        name: _asString(json['name']),
        allowed: (json['allowed'] as List?)?.map(_asInt).toList(),
        min: _asIntOrNull(json['min']),
        max: _asIntOrNull(json['max']),
        def: _asInt(json['def']),
      );
}

/// Sunucudaki sabit bildirim şablonu (`functions/src/notify.js` TEMPLATES).
class NotifyTemplate {
  final String id;
  final String label;

  /// 'normal' | 'alarm' — sabit şablonlarda sunucu belirler, serbest
  /// metinde her zaman 'normal' (team.js composeForTeam alarm'ı yasaklar).
  final String kind;

  /// true ise yalnız seçili seansa ±24 saat kala kullanılabilir.
  final bool timed;

  /// true ise metni yönetici yazar (başlık/gövde serbest metin).
  final bool custom;
  final List<String> targets;
  final NotifyTemplateParam? param;
  final String defaultTitle;
  final String defaultBody;

  const NotifyTemplate({
    required this.id,
    required this.label,
    required this.kind,
    required this.timed,
    required this.custom,
    required this.targets,
    this.param,
    required this.defaultTitle,
    required this.defaultBody,
  });

  bool get isAlarm => kind == 'alarm';

  factory NotifyTemplate.fromJson(final Map<dynamic, dynamic> json) =>
      NotifyTemplate(
        id: _asString(json['id']),
        label: _asString(json['label']),
        kind: _asString(json['kind'], 'normal'),
        timed: _asBool(json['timed']),
        custom: _asBool(json['custom']),
        targets: ((json['targets'] as List?) ?? const [])
            .map((final e) => e.toString())
            .toList(),
        param: json['param'] is Map
            ? NotifyTemplateParam.fromJson(json['param'] as Map)
            : null,
        defaultTitle: _asString(json['defaultTitle']),
        defaultBody: _asString(json['defaultBody']),
      );
}

/// `teamNotifyPreview`'ın hazırladığı gönderim öncesi metin.
class NotifyComposedMessage {
  final String title;
  final String body;
  final String kind;
  final String? template;

  const NotifyComposedMessage({
    required this.title,
    required this.body,
    required this.kind,
    this.template,
  });

  bool get isAlarm => kind == 'alarm';

  factory NotifyComposedMessage.fromJson(final Map<dynamic, dynamic> json) =>
      NotifyComposedMessage(
        title: _asString(json['title']),
        body: _asString(json['body']),
        kind: _asString(json['kind'], 'normal'),
        template: json['template'] as String?,
      );
}

/// Kalan gönderim hakları (`TeamLimits/{uid}`, saatlik/günlük/seans başına).
class NotifyQuota {
  final int hourLeft;
  final int dayLeft;
  final int targetLeft;

  const NotifyQuota({
    required this.hourLeft,
    required this.dayLeft,
    required this.targetLeft,
  });

  factory NotifyQuota.fromJson(final Map<dynamic, dynamic>? json) =>
      NotifyQuota(
        hourLeft: _asInt(json?['hourLeft'], 99),
        dayLeft: _asInt(json?['dayLeft'], 99),
        targetLeft: _asInt(json?['targetLeft'], 99),
      );
}

/// Tercih özeti — kişi listesi YOK, yalnız sayılar
/// (`functions/src/notify-prefs.js` summarize).
class NotifyPrefsSummary {
  final int of;
  final int optedOut;
  final int quietNow;
  final int willSend;

  const NotifyPrefsSummary({
    required this.of,
    required this.optedOut,
    required this.quietNow,
    required this.willSend,
  });

  factory NotifyPrefsSummary.fromJson(final Map<dynamic, dynamic>? json) =>
      NotifyPrefsSummary(
        of: _asInt(json?['of']),
        optedOut: _asInt(json?['optedOut']),
        quietNow: _asInt(json?['quietNow']),
        willSend: _asInt(json?['willSend']),
      );
}

/// `teamNotifyPreview` yanıtı — gönderimden ÖNCE kaç kişiye ulaşılacağı +
/// üretilmiş metin önizlemesi. Kişisel veri YOK, yalnız sayılar.
class NotifyPreview {
  final String targetType;
  final String targetId;
  final String targetLabel;
  final int recipients;
  final int withToken;
  final int loudOptedIn;
  final int loudOf;
  final int? tickets;
  final String? eventShow;
  final String? eventStage;
  final int? eventMs;

  /// Hazır metin önizlemesi — henüz şablon/metin seçilmediyse null.
  final NotifyComposedMessage? preview;

  /// Doluysa gönderim bu sebeple engellenir (ör. "±24 saat dışında").
  final String? blocked;
  final List<NotifyTemplate> templates;
  final NotifyQuota quota;
  final NotifyPrefsSummary prefs;
  final int now;

  const NotifyPreview({
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    required this.recipients,
    required this.withToken,
    required this.loudOptedIn,
    required this.loudOf,
    this.tickets,
    this.eventShow,
    this.eventStage,
    this.eventMs,
    this.preview,
    this.blocked,
    required this.templates,
    required this.quota,
    required this.prefs,
    required this.now,
  });

  factory NotifyPreview.fromJson(final Map<dynamic, dynamic> json) {
    final target = (json['target'] as Map?) ?? const {};
    final loudAlarm = (json['loudAlarm'] as Map?) ?? const {};
    final event = json['event'] as Map?;
    return NotifyPreview(
      targetType: _asString(target['type']),
      targetId: _asString(target['id']),
      targetLabel: _asString(target['label']),
      recipients: _asInt(json['recipients']),
      withToken: _asInt(json['withToken']),
      loudOptedIn: _asInt(loudAlarm['optedIn']),
      loudOf: _asInt(loudAlarm['of']),
      tickets: _asIntOrNull(json['tickets']),
      eventShow: event == null ? null : _asString(event['show']),
      eventStage: event == null ? null : _asString(event['stage']),
      eventMs: event == null ? null : _asIntOrNull(event['ms']),
      preview: json['preview'] is Map
          ? NotifyComposedMessage.fromJson(json['preview'] as Map)
          : null,
      blocked: json['blocked'] as String?,
      templates: ((json['templates'] as List?) ?? const [])
          .map((final e) => NotifyTemplate.fromJson(e as Map))
          .toList(),
      quota: NotifyQuota.fromJson(json['quota'] as Map?),
      prefs: NotifyPrefsSummary.fromJson(json['prefs'] as Map?),
      now: _asInt(json['now']),
    );
  }
}

/// `teamSendNotification` yanıtı.
class NotifySendResult {
  final bool ok;
  final bool duplicate;
  final String logId;
  final int recipients;
  final int withToken;
  final int inApp;
  final int loudCount;
  final int suppressedCategory;
  final int suppressedQuiet;
  final int success;
  final int failure;
  final String title;
  final String body;
  final String kind;

  const NotifySendResult({
    required this.ok,
    required this.duplicate,
    required this.logId,
    required this.recipients,
    required this.withToken,
    required this.inApp,
    required this.loudCount,
    required this.suppressedCategory,
    required this.suppressedQuiet,
    required this.success,
    required this.failure,
    required this.title,
    required this.body,
    required this.kind,
  });

  factory NotifySendResult.fromJson(final Map<dynamic, dynamic> json) {
    final suppressed = (json['suppressed'] as Map?) ?? const {};
    return NotifySendResult(
      ok: _asBool(json['ok']),
      duplicate: _asBool(json['duplicate']),
      logId: _asString(json['logId']),
      recipients: _asInt(json['recipients']),
      withToken: _asInt(json['withToken']),
      inApp: _asInt(json['inApp']),
      loudCount: _asInt(json['loudCount']),
      suppressedCategory: _asInt(suppressed['category']),
      suppressedQuiet: _asInt(suppressed['quiet']),
      success: _asInt(json['success']),
      failure: _asInt(json['failure']),
      title: _asString(json['title']),
      body: _asString(json['body']),
      kind: _asString(json['kind'], 'normal'),
    );
  }
}

/// `teamStats` içindeki bir seansın özet sayıları.
class TeamStatsEvent {
  final String eventId;
  final int ms;
  final int total;
  final int sold;
  final int held;
  final int occupancy;
  final int activeTickets;
  final int checkedIn;

  const TeamStatsEvent({
    required this.eventId,
    required this.ms,
    required this.total,
    required this.sold,
    required this.held,
    required this.occupancy,
    required this.activeTickets,
    required this.checkedIn,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(ms);

  factory TeamStatsEvent.fromJson(final Map<dynamic, dynamic> json) =>
      TeamStatsEvent(
        eventId: _asString(json['eventId']),
        ms: _asInt(json['ms']),
        total: _asInt(json['total']),
        sold: _asInt(json['sold']),
        held: _asInt(json['held']),
        occupancy: _asInt(json['occupancy']),
        activeTickets: _asInt(json['activeTickets']),
        checkedIn: _asInt(json['checkedIn']),
      );
}

/// `teamStats` içindeki toplamlar (bir oyunun tüm listelenen seansları).
class TeamStatsTotals {
  final int sold;
  final int held;
  final int total;
  final int checkedIn;

  const TeamStatsTotals({
    required this.sold,
    required this.held,
    required this.total,
    required this.checkedIn,
  });

  factory TeamStatsTotals.fromJson(final Map<dynamic, dynamic>? json) =>
      TeamStatsTotals(
        sold: _asInt(json?['sold']),
        held: _asInt(json?['held']),
        total: _asInt(json?['total']),
        checkedIn: _asInt(json?['checkedIn']),
      );
}

/// `teamStats` yanıtındaki bir oyun satırı.
class TeamStatsShow {
  final String teamId;
  final String showId;
  final String name;
  final List<TeamStatsEvent> events;
  final TeamStatsTotals totals;

  const TeamStatsShow({
    required this.teamId,
    required this.showId,
    required this.name,
    required this.events,
    required this.totals,
  });

  factory TeamStatsShow.fromJson(final Map<dynamic, dynamic> json) =>
      TeamStatsShow(
        teamId: _asString(json['teamId']),
        showId: _asString(json['showId']),
        name: _asString(json['name']),
        events: ((json['events'] as List?) ?? const [])
            .map((final e) => TeamStatsEvent.fromJson(e as Map))
            .toList(),
        totals: TeamStatsTotals.fromJson(json['totals'] as Map?),
      );
}
