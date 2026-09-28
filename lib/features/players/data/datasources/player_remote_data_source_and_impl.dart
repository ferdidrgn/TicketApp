import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/player_model.dart';

abstract class PlayerRemoteDataSource {
  Future<List<PlayerModel>> getPlayers(final bool isLimit);

  Future<List<PlayerModel>> getPlayersByIds(final List<String> playerIds);

  Future<List<PlayerModel>> searchPlayers(final String query);

  /// ➕ Admin panelinden yeni bir oyuncu oluşturur.
  Future<bool> addPlayer(final PlayerModel player, final File? imageFile);

  /// 🔄 Admin panelinden bir oyuncuyu günceller (Phase 2).
  Future<bool> updatePlayer(final String playerId,
      final Map<String, dynamic> updatedData, final File? imageFile);

  /// 🗑️ Admin panelinden bir oyuncuyu siler (Phase 2).
  Future<bool> deletePlayer(final String playerId);
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  const PlayerRemoteDataSourceImpl({
    required final FirebaseFirestore firestore,
    required final FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  CollectionReference<Map<String, dynamic>> get _collectionPath =>
      _firestore.collection('Player');

  @override
  Future<List<PlayerModel>> getPlayers(final bool isLimit) async {
    try {
      Query<Map<String, dynamic>> query = _collectionPath;

      if (isLimit)
        query = query.orderBy('_createdAt', descending: true).limit(20);

      final snapshot = await query.get();

      return _mapSnapshot(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getPlayers): ${e.message}');
    } catch (e) {
      throw Exception('Oyuncular alınamadı: $e');
    }
  }

  @override
  Future<List<PlayerModel>> getPlayersByIds(
      final List<String> playerIds) async {
    if (playerIds.isEmpty) return [];

    try {
      // Firestore 'whereIn' sorgusu en fazla 30 ID destekler.
      // Daha fazlası için chunk logic gerekir ama şimdilik standart kullanım:
      final snapshot = await _collectionPath
          .where(FieldPath.documentId, whereIn: playerIds)
          .get();

      return _mapSnapshot(snapshot);
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (getPlayersByIds): ${e.message}');
    } catch (e) {
      throw Exception('Belirtilen ID\'lerdeki oyuncular alınamadı: $e');
    }
  }

  @override
  Future<List<PlayerModel>> searchPlayers(final String query) async {
    if (query.isEmpty) return [];

    // 'firstName' üzerinden alfabetik arama (Büyük/Küçük harf duyarlılığına dikkat!)
    final snapshot = await _collectionPath
        .where('firstName', isGreaterThanOrEqualTo: query)
        .where('firstName', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return _mapSnapshot(snapshot);
  }

  @override
  Future<bool> addPlayer(final PlayerModel player, final File? imageFile) async {
    try {
      final data = player.toFirestore()
        ..['_createdAt'] = FieldValue.serverTimestamp()
        ..['_updatedAt'] = FieldValue.serverTimestamp();
      final docRef = await _collectionPath.add(data);
      await docRef.update({'_id': docRef.id});

      if (imageFile != null) {
        final ref = _storage.ref('PlayerImages/${docRef.id}.jpg');
        await ref.putFile(imageFile);
        final downloadUrl = await ref.getDownloadURL();
        await docRef.update({'imageUrl': downloadUrl});
      }
      return true;
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (addPlayer): ${e.message}');
    } catch (e) {
      throw Exception('Oyuncu eklenemedi: $e');
    }
  }

  @override
  Future<bool> updatePlayer(final String playerId,
      final Map<String, dynamic> updatedData, final File? imageFile) async {
    try {
      final data = Map<String, dynamic>.from(updatedData);

      if (imageFile != null) {
        final ref = _storage.ref('PlayerImages/$playerId.jpg');
        await ref.putFile(imageFile);
        data['imageUrl'] = await ref.getDownloadURL();
      }

      await _collectionPath.doc(playerId).update({
        ...data,
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (updatePlayer): ${e.message}');
    } catch (e) {
      throw Exception('Oyuncu güncellenemedi: $e');
    }
  }

  @override
  Future<bool> deletePlayer(final String playerId) async {
    try {
      try {
        await _storage.ref('PlayerImages/$playerId.jpg').delete();
      } catch (_) {
        // Resim yoksa hatayı yut, sorun değil.
      }
      await _collectionPath.doc(playerId).delete();
      return true;
    } on FirebaseException catch (e) {
      throw Exception('Firestore hatası (deletePlayer): ${e.message}');
    } catch (e) {
      throw Exception('Oyuncu silinemedi: $e');
    }
  }

  /// 🔥 KRİTİK METOT: Firestore dökümanlarını modele çevirirken
  /// döküman ID'sini (_id) verinin içine enjekte eder.
  List<PlayerModel> _mapSnapshot(
          final QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((final doc) {
        final data = doc.data();
        data['_id'] =
            doc.id; // Firestore Document ID'yi modelin içine koyuyoruz
        return PlayerModel.fromFirestore(data);
      }).toList();
}
