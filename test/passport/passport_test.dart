import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/passport/domain/passport.dart';

/// Test vektörleri docs/PASAPORT.md ile ve site/tools/pasaport-test.mjs ile
/// BİREBİR aynıdır (iki platformda aynı 'izlendi' tanımı).
void main() {
  final now = DateTime(2026, 10, 28, 12, 0);

  PassportTicket t(
    final String date, {
    final String used = '',
    final String pay = '',
    final bool cancelled = false,
    final String id = 't',
    final String event = '',
    final String show = '',
    final String stage = '',
    final String showName = 'Oyun',
    final String stageName = '',
  }) =>
      PassportTicket(
        id: id,
        eventId: event,
        showId: show,
        stageId: stage,
        showName: showName,
        stageName: stageName,
        eventDate: date,
        usedAt: used,
        paymentStatus: pay,
        cancelled: cancelled,
      );

  group('izlendi tanımı (V1-V15)', () {
    final vectors = <String, (PassportTicket, bool)>{
      'V1 geçmiş seans': (t('15.10.2026,20:00', pay: 'paid'), true),
      'V2 gelecek seans': (t('15.11.2026,20:00', pay: 'pay_at_venue'), false),
      'V3 gelecek ama usedAt dolu': (
        t('15.11.2026,20:00', used: '2026-10-28T10:00:00Z'),
        true
      ),
      'V4 geçmiş + cancelled': (t('15.10.2026,20:00', pay: 'cancelled'), false),
      'V5 geçmiş + no_show': (t('15.10.2026,20:00', pay: 'no_show'), false),
      'V6 geçmiş + iptal işareti': (
        t('15.10.2026,20:00', cancelled: true),
        false
      ),
      'V7 usedAt dolu + no_show': (
        t('15.10.2026,20:00', used: '2026-10-15T20:00:00Z', pay: 'no_show'),
        false
      ),
      'V8 ayrıştırılamayan tarih': (t('yakında'), false),
      'V9 boş tarih': (t(''), false),
      'V10 ISO geçmiş': (t('2026-09-01T18:00:00Z'), true),
      'V11 taşan tarih 31.02': (t('31.02.2026,20:00'), false),
      'V12 yalnız gün, dün': (t('27.10.2026'), true),
      'V13 yalnız gün, bugün (gün sonu)': (t('28.10.2026'), false),
      'V14 bir dakika önce': (t('28.10.2026,11:59'), true),
      'V15 tam şimdi': (t('28.10.2026,12:00'), false),
    };
    vectors.forEach((name, v) {
      test(name, () => expect(passportWatched(v.$1, now), v.$2));
    });
  });

  group('pasaport özeti', () {
    test('S1 karışık biletler', () {
      final p = buildPassport([
        t('10.01.2026,20:00',
            id: 'a', event: 'e1', show: 'A', stage: 'X', stageName: 'Sahne X'),
        t('10.01.2026,20:00',
            id: 'b', event: 'e1', show: 'A', stage: 'X', stageName: 'Sahne X'),
        t('10.03.2026,20:00',
            id: 'c', event: 'e2', show: 'A', stage: 'X', stageName: 'Sahne X'),
        t('05.05.2025,20:00',
            id: 'd', event: 'e3', show: 'B', stage: 'Y', stageName: 'Sahne Y'),
        t('15.12.2026,20:00', id: 'e', event: 'e4', show: 'C', stage: 'X'),
        t('01.02.2026,20:00',
            id: 'f', event: 'e5', show: 'D', stage: 'Z', cancelled: true),
      ], now);
      expect(p.watched.length, 3);
      expect(p.playCount, 2);
      expect(p.stageCount, 2);
      expect(p.thisYear, 1);
      expect(p.stamps.first.name, 'Sahne X');
      expect(p.stamps.first.count, 2);
      expect(p.watched.first.id, 'c'); // yeniden eskiye
      final b = {for (final x in p.badges) x.id: x};
      expect(b['ilk-perde']!.earned, isTrue);
      expect(b['sahne-gezgini']!.earned, isFalse);
      expect(b['sahne-gezgini']!.current, 2);
      expect(b['sadik-seyirci']!.earned, isFalse);
      expect(b['sadik-seyirci']!.current, 2);
      expect(b['sezon-yildizi']!.current, 1);
      expect(b['on-perde']!.current, 2);
      expect(p.earnedBadges, 1);
    });

    test('S2 boş durum', () {
      final p = buildPassport(const [], now);
      expect(p.isEmpty, isTrue);
      expect(p.playCount, 0);
      expect(p.earnedBadges, 0);
      expect(p.badges.every((b) => !b.earned), isTrue);
      expect(p.shareText, contains('ilk perdeyi bekliyorum'));
    });

    test('S3 sadık seyirci: aynı sahnede 3 seans', () {
      final p = buildPassport([
        for (var i = 1; i <= 3; i++)
          t('0$i.02.2026,20:00',
              id: 'x$i', event: 'e$i', show: 'S$i', stage: 'X'),
      ], now);
      final b = {for (final x in p.badges) x.id: x};
      expect(b['sadik-seyirci']!.earned, isTrue);
      expect(b['ilk-perde']!.earned, isTrue);
      expect(p.stageCount, 1);
    });

    test('S4 beş farklı sahne + beş oyun bu yıl -> 3 rozet', () {
      final p = buildPassport([
        for (var i = 1; i <= 5; i++)
          t('0$i.03.2026,20:00', id: 'y$i', event: 'e$i', show: 'S$i', stage: 'St$i'),
      ], now);
      final b = {for (final x in p.badges) x.id: x};
      expect(b['sahne-gezgini']!.earned, isTrue);
      expect(b['sezon-yildizi']!.earned, isTrue);
      expect(b['on-perde']!.earned, isFalse);
      expect(p.earnedBadges, 3);
    });

    test('S5 oyun adı yoksa sayılmaz; paylaşım metni kişisel veri içermez', () {
      final p = buildPassport([
        t('01.01.2026,20:00', id: 'z', showName: ''),
        t('01.02.2026,20:00',
            id: 'w', event: 'ew', show: 'W', stage: 'X', showName: 'Hamlet'),
      ], now);
      expect(p.playCount, 1);
      expect(p.shareText, 'TiyatRol Tiyatro Pasaportum: 1 oyun, 1 sahne, bu yıl 1 oyun, 1 rozet.');
    });
  });
}
