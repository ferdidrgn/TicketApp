import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'firebase_auth_provider.dart';

part 'storage_service.g.dart';

@riverpod
StorageService storageService(final Ref ref) => StorageService(ref);

class StorageService {
  final Ref _ref;
  StorageService(this._ref);

  FirebaseStorage get _storage => _ref.read(firebaseStorageProvider);

  Future<String?> uploadProfileImage(
      final String userId, final File file) async {
    try {
      final ref = _storage.ref().child('ppics').child('$userId.jpg');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw 'Görsel yüklenemedi: ${e.message}';
    } catch (e) {
      throw 'Beklenmedik bir hata: $e';
    }
  }

  Future<void> deleteProfileImage(final String userId) async {
    try {
      final ref = _storage.ref().child('ppics').child('$userId.jpg');
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found')
        throw 'Eski görsel silinemedi: ${e.message}';
    }
  }
}
