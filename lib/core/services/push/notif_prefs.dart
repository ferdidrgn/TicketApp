import 'package:flutter/foundation.dart';

/// Kullanıcı bildirim tercihleri — `User/{uid}.notifPrefs`
/// (sözleşme: docs/BILDIRIM-TERCIHLERI.md; sunucu: functions/src/notify-prefs.js).
///
/// Varsayılanlar sunucuyla BİREBİR: hatırlatma / değişiklik / teşekkür AÇIK;
/// yeni oyun, kampanya, sessizde sesli hatırlat KAPALI. Sessiz saat yoksa
/// `quietStart`/`quietEnd` hiç yazılmaz (ikisi birlikte geçerli olmalı).
@immutable
class NotifPrefs {
  final bool loudAlarm;
  final bool reminders;
  final bool changes;
  final bool thankYou;
  final bool newShows;
  final bool marketing;
  final String? quietStart;
  final String? quietEnd;

  const NotifPrefs({
    this.loudAlarm = false,
    this.reminders = true,
    this.changes = true,
    this.thankYou = true,
    this.newShows = false,
    this.marketing = false,
    this.quietStart,
    this.quietEnd,
  });

  static final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// "HH:MM" (00:00–23:59) mi?
  static bool isValidTime(final Object? v) => v is String && _hhmm.hasMatch(v);

  /// Biçim: sıfır dolgulu "HH:MM".
  static String formatTime(final int hour, final int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Sessiz saat tanımlı mı? (ikisi de geçerli ve farklı)
  bool get hasQuiet =>
      isValidTime(quietStart) && isValidTime(quietEnd) && quietStart != quietEnd;

  /// Ham Firestore değerinden güvenli çözüm: eksik / yanlış tür -> varsayılan.
  factory NotifPrefs.fromMap(final Object? raw) {
    if (raw is! Map) return const NotifPrefs();
    bool b(final String k, final bool def) => raw[k] is bool ? raw[k] as bool : def;
    final Object? qs = raw['quietStart'];
    final Object? qe = raw['quietEnd'];
    final bool quiet = isValidTime(qs) && isValidTime(qe) && qs != qe;
    return NotifPrefs(
      loudAlarm: b('loudAlarm', false),
      reminders: b('reminders', true),
      changes: b('changes', true),
      thankYou: b('thankYou', true),
      newShows: b('newShows', false),
      marketing: b('marketing', false),
      quietStart: quiet ? qs as String : null,
      quietEnd: quiet ? qe as String : null,
    );
  }

  /// Firestore'a yazılan tam harita (kurallar bilinmeyen anahtarı reddeder).
  Map<String, Object> toMap() => {
        'loudAlarm': loudAlarm,
        'reminders': reminders,
        'changes': changes,
        'thankYou': thankYou,
        'newShows': newShows,
        'marketing': marketing,
        if (hasQuiet) 'quietStart': quietStart!,
        if (hasQuiet) 'quietEnd': quietEnd!,
      };

  NotifPrefs copyWith({
    final bool? loudAlarm,
    final bool? reminders,
    final bool? changes,
    final bool? thankYou,
    final bool? newShows,
    final bool? marketing,
    final String? quietStart,
    final String? quietEnd,
    final bool clearQuiet = false,
  }) =>
      NotifPrefs(
        loudAlarm: loudAlarm ?? this.loudAlarm,
        reminders: reminders ?? this.reminders,
        changes: changes ?? this.changes,
        thankYou: thankYou ?? this.thankYou,
        newShows: newShows ?? this.newShows,
        marketing: marketing ?? this.marketing,
        quietStart: clearQuiet ? null : (quietStart ?? this.quietStart),
        quietEnd: clearQuiet ? null : (quietEnd ?? this.quietEnd),
      );

  @override
  bool operator ==(final Object other) =>
      other is NotifPrefs && mapEquals(toMap(), other.toMap());

  @override
  int get hashCode => Object.hashAll(toMap().entries.map((e) => Object.hash(e.key, e.value)));
}

/// Tercihlerin saklandığı yer. Üretimde Firestore; testte sahte.
abstract class NotifPrefsRemote {
  /// Oturum yoksa / anonimse `null` (ayarlarda bölüm gizlenir).
  Future<NotifPrefs?> read();

  /// Yalnız kategori + sessiz saat alanlarını yazar (`loudAlarm` cihaz akışına ait, dokunulmaz).
  Future<void> write(final NotifPrefs prefs);
}
