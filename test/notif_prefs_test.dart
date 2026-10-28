import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/core/services/push/notif_prefs.dart';
import 'package:ticketapp/core/services/push/notif_prefs_provider.dart';

/// Sahte saklama: Firestore yok. `failWrites` yazımı reddeder.
class FakeRemote implements NotifPrefsRemote {
  NotifPrefs? stored;
  final List<NotifPrefs> writes = [];
  bool failWrites = false;
  FakeRemote(this.stored);

  @override
  Future<NotifPrefs?> read() async => stored;

  @override
  Future<void> write(final NotifPrefs prefs) async {
    if (failWrites) throw Exception('offline');
    writes.add(prefs);
    stored = prefs;
  }
}

void main() {
  group('NotifPrefs modeli (sözleşme: docs/BILDIRIM-TERCIHLERI.md)', () {
    test('varsayılanlar sunucuyla aynı', () {
      const NotifPrefs p = NotifPrefs();
      expect(
          [p.reminders, p.changes, p.thankYou, p.newShows, p.marketing, p.loudAlarm],
          [true, true, true, false, false, false]);
      expect(p.hasQuiet, isFalse);
      for (final Object? raw in [null, 5, 'x', <String, Object?>{}, <int>[]]) {
        expect(NotifPrefs.fromMap(raw), const NotifPrefs(), reason: '$raw');
      }
    });

    test('fromMap yanlış tür / geçersiz saati yok sayar (savunmacı)', () {
      final NotifPrefs p = NotifPrefs.fromMap({
        'reminders': 'hayır',
        'newShows': true,
        'changes': 1,
        'quietStart': '25:00',
        'quietEnd': '08:00',
      });
      expect(p.reminders, isTrue);
      expect(p.newShows, isTrue);
      expect(p.changes, isTrue);
      expect(p.hasQuiet, isFalse);
      expect(NotifPrefs.fromMap({'quietStart': '22:00'}).hasQuiet, isFalse);
      expect(NotifPrefs.fromMap({'quietStart': '22:00', 'quietEnd': '22:00'}).hasQuiet, isFalse);
      expect(NotifPrefs.fromMap({'quietStart': '22:00', 'quietEnd': '07:30'}).quietEnd, '07:30');
    });

    test('toMap yalnız izinli anahtarları yazar; sessiz saat yoksa quiet* hiç yazılmaz', () {
      const allowed = {
        'loudAlarm', 'reminders', 'changes', 'thankYou', 'newShows',
        'marketing', 'quietStart', 'quietEnd'
      };
      final Map<String, Object> m = const NotifPrefs().toMap();
      expect(allowed.containsAll(m.keys), isTrue);
      expect(m.containsKey('quietStart'), isFalse);
      expect(m.containsKey('quietEnd'), isFalse);
      final Map<String, Object> q =
          const NotifPrefs(quietStart: '23:00', quietEnd: '08:00').toMap();
      expect(q['quietStart'], '23:00');
      expect(allowed.containsAll(q.keys), isTrue);
      // geri okuma özdeş
      expect(NotifPrefs.fromMap(q), const NotifPrefs(quietStart: '23:00', quietEnd: '08:00'));
    });

    test('copyWith + clearQuiet + eşitlik + saat biçimi', () {
      final NotifPrefs a = const NotifPrefs().copyWith(quietStart: '23:00', quietEnd: '08:00');
      expect(a.hasQuiet, isTrue);
      expect(a.copyWith(clearQuiet: true).hasQuiet, isFalse);
      expect(a.copyWith(reminders: false) == a, isFalse);
      expect(const NotifPrefs() == const NotifPrefs(), isTrue);
      expect(NotifPrefs.formatTime(7, 5), '07:05');
      expect(NotifPrefs.isValidTime('07:05'), isTrue);
      expect(NotifPrefs.isValidTime('7:05'), isFalse);
      expect(NotifPrefs.isValidTime(705), isFalse);
    });
  });

  group('NotifPrefsNotifier (sahte saklama)', () {
    ProviderContainer make(final FakeRemote r) {
      final ProviderContainer c = ProviderContainer(
          overrides: [notifPrefsRemoteProvider.overrideWithValue(r)]);
      addTearDown(c.dispose);
      return c;
    }

    test('oturum yoksa (null) değişiklik yapılmaz', () async {
      final FakeRemote r = FakeRemote(null);
      final ProviderContainer c = make(r);
      expect(await c.read(notifPrefsProvider.future), isNull);
      expect(await c.read(notifPrefsProvider.notifier).change((o) => o.copyWith(reminders: false)), isFalse);
      expect(r.writes, isEmpty);
    });

    test('değişiklik yazılır; değişmeyen değer yazılmaz; yazım hatasında eski değere döner', () async {
      final FakeRemote r = FakeRemote(const NotifPrefs());
      final ProviderContainer c = make(r);
      await c.read(notifPrefsProvider.future);
      final NotifPrefsNotifier n = c.read(notifPrefsProvider.notifier);
      expect(await n.change((o) => o.copyWith(newShows: true)), isTrue);
      expect(c.read(notifPrefsProvider).value!.newShows, isTrue);
      expect(r.writes.length, 1);
      expect(await n.change((o) => o), isTrue);
      expect(r.writes.length, 1); // değişiklik yok -> yazım yok
      r.failWrites = true;
      expect(await n.change((o) => o.copyWith(marketing: true)), isFalse);
      expect(c.read(notifPrefsProvider).value!.marketing, isFalse); // geri alındı
      expect(c.read(notifPrefsProvider).value!.newShows, isTrue);
    });

    test('sessiz saat aç / kapat', () async {
      final FakeRemote r = FakeRemote(const NotifPrefs());
      final ProviderContainer c = make(r);
      await c.read(notifPrefsProvider.future);
      final NotifPrefsNotifier n = c.read(notifPrefsProvider.notifier);
      await n.change((o) => o.copyWith(quietStart: '23:00', quietEnd: '08:00'));
      expect(r.stored!.hasQuiet, isTrue);
      await n.change((o) => o.copyWith(clearQuiet: true));
      expect(r.stored!.hasQuiet, isFalse);
      expect(r.stored!.toMap().containsKey('quietStart'), isFalse);
    });
  });
}
