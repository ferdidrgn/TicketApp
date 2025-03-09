import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/util/date_formatter.dart';
import '../../model/user.dart';

abstract class UserRemoteDataSource {
  Future<void> saveUser(final User user, final String downloadUrl,
      {final bool isUpdate = false});

  Future<User?> getUserById(final String userId);

  Future<void> deleteUser(final String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore firestore;

  UserRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> saveUser(final User user, final String downloadUrl,
      {final bool isUpdate = false}) async {
    try {
      final docSnapshot = await firestore.collection('User').doc(user.id).get();

      if (docSnapshot.exists && !isUpdate) {
        print(
            'User with ID ${user.id} already exists. Skipping save operation.');
        return; // İşlemi sonlandır
      }

      final userMap = _mapUserToFirestore(user, downloadUrl, isUpdate);
      isUpdate
          ? await firestore.collection('User').doc(user.id).update(userMap)
          : await firestore.collection('User').doc(user.id).set(userMap);
    } catch (e) {
      throw Exception('Error saving user: $e');
    }
  }

  @override
  Future<User?> getUserById(final String userId) async {
    try {
      final DocumentSnapshot doc =
          await firestore.collection('User').doc(userId).get();
      if (doc.exists) {
        return _mapDocumentToUser(doc);
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

  User _mapDocumentToUser(final DocumentSnapshot document) {
    return User(
      id: _getStringField(document, '_id'),
      createdAt: _getStringField(document, '_createdAt'),
      updatedAt: _getStringField(document, '_updatedAt'),
      firstName: _getStringField(document, 'firstName'),
      lastName: _getStringField(document, 'lastName'),
      imageUrl: _getStringField(document, 'imageUrl'),
      phoneNumber: _getStringField(document, 'phoneNumber'),
      age: int.tryParse(_getStringField(document, 'age')) ?? 0,
      eMail: _getStringField(document, 'eMail'),
      city: _getStringField(document, 'city'),
      isPhoneActive: document['isPhoneActive'],
      fcmToken: _getStringField(document, 'fcmToken'),
      role: _getStringField(document, 'role'),
      favoriteShows: _getListField(document, 'favoriteShows'),
      favoriteStages: _getListField(document, 'favoriteStages'),
      favoritePlayers: _getListField(document, 'favoritePlayers'),
      ticketsId: _getListField(document, "ticketsId"),
    );
  }

  String _getStringField(
      final DocumentSnapshot document, final String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  List<String> _getListField(
      final DocumentSnapshot document, final String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }

  Map<String, dynamic> _mapUserToFirestore(
      final User user, final String downloadUrl, final bool isUpdate) {
    final nowTime = DateFormatter.nowFormatDateTime();

    final userMap = <String, dynamic>{
      if (!isUpdate) '_createdAt': nowTime,
      '_updatedAt': nowTime,
      '_id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'phoneNumber': user.phoneNumber,
      'imageUrl': downloadUrl,
      'isPhoneActive': user.isPhoneActive,
      'age': user.age,
      'eMail': user.eMail,
      'fcmToken': user.fcmToken,
      'role': user.role,
      'city': user.city,
      'favoriteShows': user.favoriteShows,
      'favoriteStages': user.favoriteStages,
      'favoritePlayers': user.favoritePlayers,
      'ticketsId': user.ticketsId,
    };
    return userMap;
  }
}
