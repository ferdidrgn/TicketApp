import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/reviews/data/review_repository.dart';

Review r(final String show, final int rating, {final bool hidden = false}) =>
    Review(
      id: '${show}_$rating',
      showId: show,
      userId: 'u',
      userName: 'A',
      userImage: '',
      rating: rating,
      text: '',
      createdAt: null,
      updatedAt: null,
      hidden: hidden,
    );

void main() {
  test('ortalama ve dağılım hesaplanır, gizli yorum sayılmaz', () {
    final stats = ReviewStat.fromReviews([
      r('a', 5),
      r('a', 3),
      r('a', 1, hidden: true),
      r('b', 4),
    ]);
    expect(stats['a']!.count, 2);
    expect(stats['a']!.average, 4.0);
    expect(stats['a']!.distribution, [0, 0, 1, 0, 1]);
    expect(stats['b']!.average, 4.0);
  });

  test('yorum belge kimliği kullanıcı_oyun', () {
    expect(Review.docId('u1', 's9'), 'u1_s9');
  });
}
