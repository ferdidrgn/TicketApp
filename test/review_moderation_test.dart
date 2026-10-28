import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/reviews/data/review_repository.dart';

void main() {
  test('sunucu hata kodlari kullanici mesajina cevrilir', () {
    expect(ReviewRepository.mapErrorMessage('failed-precondition', 'NOT_VERIFIED_ATTENDEE', null),
        contains('izlemiş olman'));
    expect(ReviewRepository.mapErrorMessage('failed-precondition', 'PHONE_REQUIRED', null),
        contains('telefon'));
    expect(ReviewRepository.mapErrorMessage('failed-precondition', 'REVIEW_LOCKED', null),
        contains('moderasyon'));
    expect(ReviewRepository.mapErrorMessage('resource-exhausted', 'resource-exhausted', null),
        contains('sık'));
    expect(ReviewRepository.mapErrorMessage('invalid-argument', 'invalid-argument', 'Yorumda bağlantı (URL) olamaz.'),
        'Yorumda bağlantı (URL) olamaz.');
    expect(ReviewRepository.mapErrorMessage('internal', 'internal', 'x'), contains('tamamlanamadı'));
  });

  test('Review.fromDoc dogrulanmis rozeti ve durumu okur; eski belge rozetsiz', () {
    final r = Review.fromDoc('u_s', {'showId': 's', 'userId': 'u', 'rating': 4, 'text': 'iyi', 'hidden': true, 'status': 'pending', 'verified': true});
    expect(r.verified, isTrue);
    expect(r.status, 'pending');
    expect(r.hidden, isTrue);
    final eski = Review.fromDoc('u_s', {'showId': 's', 'userId': 'u', 'rating': 4, 'text': '', 'hidden': false});
    expect(eski.verified, isFalse);
    expect(eski.status, 'published');
  });

  test('ReviewEligibility aciklamasi koda gore', () {
    expect(const ReviewEligibility(false, 'PHONE_REQUIRED', false).reason, contains('telefon'));
    expect(const ReviewEligibility(false, 'NOT_VERIFIED_ATTENDEE', false).reason, contains('izlemiş olman'));
  });
}
