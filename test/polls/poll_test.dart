import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/polls/data/poll_repository.dart';

void main() {
  Map<String, dynamic> doc({String status = 'active', int startH = -1, int endH = 48}) => {
        'question': 'Sonraki sezon?',
        'options': [
          {'id': 'o1', 'label': 'Hamlet'},
          {'id': 'o2', 'label': 'Macbeth', 'showId': 's1'},
        ],
        'counts': {'o1': 3, 'o2': 1},
        'totalVotes': 4,
        'status': status,
        'startsAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: startH))),
        'endsAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: endH))),
      };

  test('Poll.fromDoc alanları okur; yüzde ve açık/kapalı doğru', () {
    final p = Poll.fromDoc('p1', doc());
    expect(p.options.length, 2);
    expect(p.options[1].showId, 's1');
    expect(p.percentOf('o1'), 75);
    expect(p.percentOf('o2'), 25);
    expect(p.isOpen(), isTrue);
    expect(Poll.fromDoc('p', doc(status: 'closed')).isOpen(), isFalse);
    expect(Poll.fromDoc('p', doc(endH: -1)).isOpen(), isFalse);
    expect(Poll.fromDoc('p', doc(startH: 2)).isOpen(), isFalse);
  });

  test('oy yokken yüzde 0 (sıfıra bölme yok)', () {
    final p = Poll.fromDoc('p', {...doc(), 'counts': {}, 'totalVotes': 0});
    expect(p.percentOf('o1'), 0);
  });

  test('hata kodları kullanıcı mesajına çevrilir', () {
    expect(PollRepository.mapErrorMessage('failed-precondition', 'PHONE_REQUIRED', null), contains('telefon'));
    expect(PollRepository.mapErrorMessage('resource-exhausted', 'resource-exhausted', null), contains('sık'));
    expect(PollRepository.mapErrorMessage('failed-precondition', 'x', null), contains('kabul etmiyor'));
    expect(PlanRepository.planUrl('abc123'), 'https://tiyatrol.web.app/plan/abc123');
    expect(PlanRepository.mapErrorMessage('resource-exhausted', null), contains('sık'));
  });
}
