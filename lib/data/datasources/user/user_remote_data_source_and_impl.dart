import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/user_model.dart';

abstract class UserRemoteDataSource {
  Future<void> saveUser(final UserModel user, final String downloadUrl,
      {final bool isUpdate = false});

  Future<UserModel?> getUserById(final String userId);

  Future<void> deleteUser(final String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore firestore;

  UserRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> saveUser(final UserModel user, final String downloadUrl,
      {final bool isUpdate = false}) async {
    try {
      final docRef = firestore.collection('User').doc(user.id);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && !isUpdate) {
        print(
            'User with ID ${user.id} already exists. Skipping save operation.');
        return; // İşlemi sonlandır
      }

      final Map<String, dynamic> userMap = user.toFirestore()
        ..['imageUrl'] = downloadUrl;

      isUpdate ? await docRef.update(userMap) : await docRef.set(userMap);
    } catch (e) {
      throw Exception('Error saving user: $e');
    }
  }

  @override
  Future<UserModel?> getUserById(final String userId) async {
    try {
      final DocumentSnapshot doc =
          await firestore.collection('User').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()! as Map<String, dynamic>);
      } else {
        throw Exception("Kullanıcı bulunamadı.");
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  @override
  Future<void> deleteUser(final String userId) async {
    try {
      await firestore.collection('User').doc(userId).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}
