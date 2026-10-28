import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/settings/presentation/widgets/loud_alarm_sheet.dart';

void main() {
  group('Sessizde sesli hatırlatma metni (dürüstlük)', () {
    test('Android: sessiz ayarını DEĞİŞTİRMEDİĞİNİ ve DND kuralını açıkça yazar',
        () {
      final LoudAlarmCopy tr = LoudAlarmCopy.of(false, TargetPlatform.android);
      expect(tr.wontDo, contains('DEĞİŞTİRMEYİZ'));
      expect(tr.wontDo, contains('sessizde değilse'));
      expect(tr.limits, contains('Rahatsız Etme'));
      final LoudAlarmCopy en = LoudAlarmCopy.of(true, TargetPlatform.android);
      expect(en.wontDo, contains('do NOT change'));
      expect(en.limits, contains('Do Not Disturb'));
    });

    test('iOS: sessiz anahtarı açıkken ses çıkmayacağını abartmadan söyler', () {
      final LoudAlarmCopy tr = LoudAlarmCopy.of(false, TargetPlatform.iOS);
      expect(tr.limits, contains('sessiz anahtarı'));
      expect(tr.what, contains('Zamana duyarlı'));
      expect(tr.what, isNot(contains('sessizde olsa bile')));
      final LoudAlarmCopy en = LoudAlarmCopy.of(true, TargetPlatform.iOS);
      expect(en.limits, contains('silent switch'));
    });
  });
}
