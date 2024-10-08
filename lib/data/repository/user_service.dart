import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/util/date_formatter.dart';
import '../model/user.dart';

class UserService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('User');

  // Create or update user
  Future<void> saveUser(User user, String downloadUrl,
      {bool isUpdate = false}) async {
    try {
      // Belgeyi kontrol et
      final docSnapshot = await _userCollection.doc(user.id).get();

      if (docSnapshot.exists && !isUpdate) {
        // Eğer belge mevcutsa ve update değilse, işlemi atla
        print('User with ID ${user.id} already exists. Skipping save operation.');
        return; // İşlemi sonlandır
      }

      final userMap = _mapUserToFirestore(user, downloadUrl, isUpdate);
      isUpdate
          ? await _userCollection.doc(user.id).update(userMap)
          : await _userCollection.doc(user.id).set(userMap);
    } catch (e) {
      throw Exception('Error saving user: $e');
    }
  }

  // Fetch user by ID
  Future<User?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _userCollection.doc(userId).get();
      if (doc.exists) {
        return _mapDocumentToUser(doc);
      } else {
        throw Exception("Kullanıcı bulunamadı.");
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Delete user by ID
  Future<void> deleteUser(String userId) async {
    try {
      await _userCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Map Firestore document to User model
  User _mapDocumentToUser(DocumentSnapshot document) {
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
        ticketsId: _getListField(document, "ticketsId"));
  }

  String _getStringField(DocumentSnapshot document, String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  List<String> _getListField(DocumentSnapshot document, String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }

  // Map User model to Firestore data
  Map<String, dynamic> _mapUserToFirestore(
      User user, String downloadUrl, bool isUpdate) {
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
      'ticketsId': user.ticketsId
    };
    return userMap;
  }
}
