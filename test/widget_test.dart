// Bu dosya `flutter create`'in varsayılan sayaç (counter) widget testiydi —
// uygulamada hiç var olmayan bir "+" ikonu ve "0"/"1" metnini arıyordu,
// gerçek `MyApp()`'i pompalamak da Firebase/Riverpod başlatmasını test
// ortamında mock'lamadan CI'da güvenilir şekilde çalışmazdı.
//
// Onun yerine bu session'da bulunup düzeltilen en kritik regresyonu
// (DateFormatter'ın gerçek Firestore tarih formatını hiç ayrıştıramaması —
// "0 aktif oyun" ve hero panelinin yanlış gösteriye düşmesinin kök nedeni)
// kilitleyen gerçek, Firebase gerektirmeyen bir birim testi konuldu.
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/core/util/date_formatter.dart';

void main() {
  group('DateFormatter.parseDateString', () {
    test('gerçek Firestore formatını (virgülden sonra boşluksuz) ayrıştırır',
        () {
      final date = DateFormatter.parseDateString('15.10.2026,22:00');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 10);
      expect(date.day, 15);
      expect(date.hour, 22);
      expect(date.minute, 0);
    });

    test('boşluklu varyantı da (geriye dönük uyumluluk) ayrıştırır', () {
      final date = DateFormatter.parseDateString('15.10.2026, 22:00');
      expect(date, isNotNull);
      expect(date!.day, 15);
      expect(date.hour, 22);
    });

    test('geçersiz/boş girdide null döner, asla fırlatmaz', () {
      expect(DateFormatter.parseDateString(null), isNull);
      expect(DateFormatter.parseDateString(''), isNull);
      expect(DateFormatter.parseDateString('geçersiz-tarih'), isNull);
    });
  });
}
