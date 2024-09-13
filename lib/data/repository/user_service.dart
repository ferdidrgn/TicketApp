import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import '../model/user.dart';

class UserService {
  final CollectionReference _userCollection =
  FirebaseFirestore.instance.collection('User');
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

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
      SnackBar(content: Text('Error saving user: $e'));
    }
  }

  // Fetch user by ID
  Future<User?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _userCollection.doc(userId).get();
      if (!doc.exists) return null;
      return _mapDocumentToUser(doc);
    } catch (e) {
      SnackBar(content: Text('Error fetching user: $e'));
      return null;
    }
  }

  // Delete user by ID
  Future<void> deleteUser(String userId) async {
    try {
      await _userCollection.doc(userId).delete();
    } catch (e) {
      SnackBar(content: Text('Error deleting user: $e'));
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
    );
  }

  String _getStringField(DocumentSnapshot document, String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  // Map User model to Firestore data
  Map<String, dynamic> _mapUserToFirestore(
      User user, String downloadUrl, bool isUpdate) {
    final userMap = <String, dynamic>{
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
      if (!isUpdate) '_createdAt': Timestamp.now(),
      '_updatedAt': Timestamp.now(),
    };
    return userMap;
  }

  // Firebase Authentication - Email ve Şifre ile Oturum Açma
  Future<auth.User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user; // Oturum açan kullanıcıyı döner
    } catch (e) {
      SnackBar(content: Text('Error signing in: $e'));
      return null;
    }
  }

  // Firebase Authentication - Oturum Kapatma
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      SnackBar(content: Text('Error signing out: $e'));
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
      SnackBar(content: Text('Error creating user: $e'));
      return null;
    }
  }

  // Kullanıcının Oturum Açmış mı Kontrol Etme
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}