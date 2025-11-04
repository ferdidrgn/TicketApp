import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/user_model.dart';

abstract class UserRemoteDataSource {
  Future<bool> saveUser(final UserModel user, final String downloadUrl,
      {final bool isUpdate = false});

  Future<UserModel?> getUserById(final String userId);
  Future<bool> deleteUser(final String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const _collection = 'User';

  UserRemoteDataSourceImpl({required final FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<bool> saveUser(final UserModel user, final String downloadUrl,
      {final bool isUpdate = false}) async {
    final docRef = _firestore.collection(_collection).doc(user.id);

    try {
      final exists = (await docRef.get()).exists;
      if (exists && !isUpdate) return false;

      final userMap = {
        ...user.toFirestore(),
        'imageUrl': downloadUrl,
      };

      await (isUpdate ? docRef.update(userMap) : docRef.set(userMap));
      return true;
    } catch (e, s) {
      throw Exception('Failed to save user → $e\n$s');
    }
  }

  @override
  Future<UserModel?> getUserById(final String userId) async {
    if (userId.isEmpty) throw Exception('User ID cannot be empty');

    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      return doc.exists ? UserModel.fromFirestore(doc.data()) : null;
    } catch (e, s) {
      throw Exception('Failed to fetch user → $e\n$s');
    }
  }

  @override
  Future<bool> deleteUser(final String userId) async {
    if (userId.isEmpty) return false;

    try {
      await _firestore.collection(_collection).doc(userId).delete();
      return true;
    } on FirebaseException catch (e) {
      return false;
    } catch (e, s) {
      return false;
    }
  }
}
