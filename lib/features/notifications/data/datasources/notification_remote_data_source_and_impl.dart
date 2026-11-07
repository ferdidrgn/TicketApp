import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  // NOT (13.11.2026): create YOK — bkz. notification_repository.dart notu.
  // Notification yazımı yalnız sunucuda (Cloud Functions); istemci
  // firestore.rules'ta `allow create: if false` ile zaten reddedilir.
  Stream<List<NotificationModel>> watchNotificationsForUser(
      final String userId);
  Future<bool> markNotificationRead(final String notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Notification';

  NotificationRemoteDataSourceImpl(
      {required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<NotificationModel>> watchNotificationsForUser(
      final String userId) {
    if (userId.isEmpty) return Stream.value(const []);

    // NOT: Bilinçli olarak orderBy KULLANILMIYOR — Firestore'da userId +
    // tarih sıralaması bileşik index gerektirir (bu sandbox'ta deploy
    // imkanı yok). Sıralama presentation katmanında (createdAt'e göre)
    // yapılıyor; bkz. notification_provider.dart.
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((final snapshot) => snapshot.docs.map((final doc) {
              final data = doc.data();
              data['_id'] = doc.id;
              return NotificationModel.fromFirestore(data);
            }).toList());
  }

  @override
  Future<bool> markNotificationRead(final String notificationId) async {
    if (notificationId.isEmpty)
      throw Exception('Notification ID cannot be empty.');

    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
      return true;
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}
