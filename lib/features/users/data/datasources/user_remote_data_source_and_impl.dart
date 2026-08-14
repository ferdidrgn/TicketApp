import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<bool> saveUser(final UserModel user, final String? downloadUrl,
      {final bool isUpdate = false});

  Future<UserModel?> getUserById(final String userId);

  Future<bool> deleteUser(final String userId);

  Future<bool> setFavorite(final String userId, final String itemId,
      final String fieldName, final bool shouldBeFavorite);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'User';

  UserRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<bool> saveUser(final UserModel user, final String? downloadUrl,
      {final bool isUpdate = false}) async {
    // ID kontrolü
    if (user.id == null || user.id!.isEmpty)
      throw Exception('User ID cannot be empty');

    final docRef = _firestore.collection(_collection).doc(user.id);

    try {
      // Eğer update değilse (create ise) ve kullanıcı zaten varsa hata fırlatılabilir
      // veya mevcut mantıktaki gibi false dönebilir. Senior yapıda logic net olmalı.
      // Mevcut mantığı koruyoruz:
      if (!isUpdate) {
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) return false;
      }

      var userMap = user.toFirestore();

      // Eğer resim URL'i geldiyse map'e ekle
      if (downloadUrl != null && downloadUrl.isNotEmpty)
        userMap['imageUrl'] = downloadUrl;

      if (isUpdate) {
        // Güncelleme işleminde merge: true veya sadece update kullanmak güvenlidir
        // _updatedAt alanını server timestamp ile güncellemek iyi pratiktir
        userMap['_updatedAt'] = FieldValue.serverTimestamp();
        await docRef.update(userMap);
      } else
        await docRef.set(userMap);

      return true;
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  @override
  Future<UserModel?> getUserById(final String userId) async {
    if (userId.isEmpty) throw Exception('User ID cannot be empty');

    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();

      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      data['_id'] = doc.id; // ID enjeksiyonu

      // Map<String, dynamic> olduğunu garanti ederek gönderiyoruz
      return UserModel.fromFirestore(data);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<bool> deleteUser(final String userId) async {
    if (userId.isEmpty) throw Exception('User ID cannot be empty');

    try {
      await _firestore.collection(_collection).doc(userId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  @override
  Future<bool> setFavorite(final String userId, final String itemId,
      final String fieldName, final bool shouldBeFavorite) async {
    if (userId.isEmpty || itemId.isEmpty)
      throw Exception('User ID / Item ID cannot be empty');

    try {
      await _firestore.collection(_collection).doc(userId).update({
        fieldName: shouldBeFavorite
            ? FieldValue.arrayUnion([itemId])
            : FieldValue.arrayRemove([itemId]),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update favorite: $e');
    }
  }
}
