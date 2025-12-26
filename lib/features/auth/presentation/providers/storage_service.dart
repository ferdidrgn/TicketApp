import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Dosyayı yükler ve indirme URL'sini döner
  Future<String?> uploadProfileImage(
      final String userId, final File file) async {
    try {
      // Kayıt yolu: ppics/userId.jpg
      final ref = _storage.ref().child('ppics').child('$userId.jpg');

      // Yükleme işlemi
      final uploadTask = await ref.putFile(file);

      // URL'yi al
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }
}
