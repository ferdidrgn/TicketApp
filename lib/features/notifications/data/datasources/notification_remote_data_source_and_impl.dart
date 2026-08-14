import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  /// Kullanıcının görebileceği bildirimleri (targetUserId 'all' veya kendi
  /// uid'si olanlar) en yeniden en eskiye canlı olarak yayınlar.
  Stream<List<NotificationModel>> streamNotifications(final String? userId);

  Future<void> markAsRead(final String notificationId, final String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Notification';
  static const _limit = 50;

  NotificationRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<NotificationModel>> streamNotifications(final String? userId) {
    final audiences = userId != null ? ['all', userId] : ['all'];

    return _firestore
        .collection(_collection)
        .where('targetUserId', whereIn: audiences)
        .orderBy('_createdAt', descending: true)
        .limit(_limit)
        .snapshots()
        .map((final snapshot) => snapshot.docs.map((final doc) {
              final data = doc.data();
              data['_id'] = doc.id;
              return NotificationModel.fromFirestore(data);
            }).toList());
  }

  @override
  Future<void> markAsRead(final String notificationId, final String userId) async {
    if (notificationId.isEmpty || userId.isEmpty) return;
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Bildirim okunmuş olarak işaretlenemedi: $e');
    }
  }
}
