import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/auth/presentation/providers/storage_provider.dart';

// Servis sağlayıcı
final storageServiceProvider =
    Provider<StorageService>((final ref) => StorageService(ref));

class StorageService {
  final Ref _ref;

  StorageService(this._ref);

  // FirebaseStorage'ı provider'dan çekiyoruz
  FirebaseStorage get _storage => _ref.read(storageProvider);

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
