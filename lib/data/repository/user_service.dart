import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../model/user.dart';

class UserService {
  static final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('User');

  // Create or update user
  Future<void> saveUser(User user, String downloadUrl,
      {bool isUpdate = false}) async {
    try {
      final userMap = _mapUserToFirestore(user, downloadUrl, isUpdate);
      if (isUpdate) {
        await _userCollection.doc(user.id).update(userMap);
      } else {
        await _userCollection.doc(user.id).set(userMap);
      }
    } catch (e) {
      throw Exception('Error saving user: $e');
    }
  }

  // Fetch user by ID
  Future<User?> getUserById(String userId) async {
    try {
      QuerySnapshot result =
          await _userCollection.where('_id', isEqualTo: userId).limit(1).get();
      if (result.docs.isEmpty) return null;
      return _mapDocumentToUser(result.docs.first);
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
        imageUrl: _getStringField(document, 'photoUrl'),
        phone: _getStringField(document, 'phoneNumber'),
        age: int.tryParse(_getStringField(document, 'age')) ?? 0,
        mail: _getStringField(document, 'eMail'),
        city: _getStringField(document, 'city'),
        isPhoneActive: document['isActivite'],
        fcmToken: _getStringField(document, 'fcmToken'),
        role: _getStringField(document, 'role'),
        favoriteShows: _getListField(document, 'favoriteShows'),
        favoriteStages: _getListField(document, 'favoriteStages'),
        favoritePlayers: _getListField(document, 'favoritePlayers'));
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
    final userMap = <String, dynamic>{
      if (!isUpdate) '_createdAt': Timestamp.now(),
      '_updatedAt': Timestamp.now(),
      '_id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'fullName': '${user.firstName} ${user.lastName}',
      'phoneNumber': user.phone,
      'photoUrl': downloadUrl,
      'isActivite': user.isPhoneActive,
      'age': user.age,
      'eMail': user.mail,
      'fcmToken': user.fcmToken,
      'role': user.role,
      'city': user.city,
      'favoriteShows': user.favoriteShows,
      'favoriteStages': user.favoriteStages,
      'favoritePlayers': user.favoritePlayers,
    };
    return userMap;
  }

  // Firebase Authentication - Email ve Şifre ile Oturum Açma
  Future<auth.User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user; // Oturum açan kullanıcıyı döner
    } catch (e) {
      throw Exception('Error signing in: $e');
    }
  }

  // Firebase Authentication - Oturum Kapatma
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  // Firebase Authentication - Yeni Kullanıcı Oluşturma
  Future<auth.User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      throw Exception('Error signing up: $e');
    }
  }

  // Açık oturumdaki user bilgileri
  get currentUser => _auth.currentUser;

  // Kullanıcının Oturum Açmış mı Kontrol Etme
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}
