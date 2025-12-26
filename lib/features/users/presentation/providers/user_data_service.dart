import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart' as entity;

/// 👤 Firestore User Data Service
///
/// Bu servis şunları yapar:
/// 1. ✅ Firestore'da 'User' koleksiyonunu yönetir.
/// 2. ✅ Google Auth verilerinin özel profil verilerini ezmesini engeller.
/// 3. ✅ Kullanıcı silindiğinde ilişkili tüm biletleri (Ticket koleksiyonu) temizler.
/// 4. ✅ Bilet satın alma veya iptal durumlarında kullanıcı dokümanını günceller.
class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Koleksiyon İsimleri
  static const String _usersCollection = 'User';
  static const String _ticketsCollection = 'Ticket';

  // ========================================
  // CREATE & UPDATE (SMART UPDATE)
  // ========================================

  /// 💾 Kullanıcıyı Firestore'a kaydeder veya günceller.
  ///
  /// @param user - Kaydedilecek kullanıcı varlığı.
  /// @param isUpdate - True ise mevcut veriyi akıllıca birleştirir (merge/update).
  Future<bool> saveUser({
    required final entity.User user,
    final bool isUpdate = false,
  }) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final Map<String, dynamic> data = userModel.toFirestore();

      if (isUpdate) {
        // ⚡ GÜVENLİK FİLTRESİ: Mevcut verileri koru
        data.removeWhere((final key, final value) {
          // Null veya boş stringleri temizle ki Firestore'daki mevcut veriyi silmesin.
          if (value == null) return true;
          if (value is String && value.isEmpty) return true;

          // GOOGLE FOTOĞRAFI KORUMASI:
          // Eğer gelen link Google kaynaklıysa, kullanıcının yüklediği özel resmi (Storage) ezme.
          if (key == 'imageUrl' &&
              value is String &&
              value.contains('googleusercontent.com')) {
            return true;
          }
          return false;
        });

        data['_updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection(_usersCollection).doc(user.id).update(data);
      } else {
        // Yeni kayıt oluşturulurken tarih damgalarını ekle.
        data['_createdAt'] = FieldValue.serverTimestamp();
        data['_updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection(_usersCollection).doc(user.id).set(data);
      }
      return true;
    } catch (e) {
      // Doküman bulunamadıysa (ilk giriş), set işlemi ile yeni kayıt oluştur.
      if (isUpdate && e is FirebaseException && e.code == 'not-found') {
        return saveUser(user: user, isUpdate: false);
      }
      return false;
    }
  }

  /// 🔄 Firebase Auth'tan gelen bilgileri Firestore'a senkronize eder.
  /// Google'dan gelen verileri süzgeçten geçirerek Firestore'a aktarır.
  Future<bool> syncUserFromAuth({
    required final String userId,
    required final String displayName,
    required final String email,
    required final String photoUrl,
    required final String phoneNumber,
    required final String role,
    required final bool isPhoneActive,
  }) async {
    try {
      final exists = await userExists(userId);
      final nameParts = _splitName(displayName);

      final user = entity.User(
        id: userId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        firstName: nameParts['firstName'] ?? '',
        lastName: nameParts['lastName'] ?? '',
        imageUrl: photoUrl,
        eMail: email,
        phoneNumber: phoneNumber,
        role: role,
        age: 0,
        city: '',
        isPhoneActive: isPhoneActive,
        fcmToken: '',
        // Boş gönderilir, saveUser içindeki filtre mevcut tokenı korur.
        favoriteShows: const [],
        favoriteStages: const [],
        favoritePlayers: const [],
        ticketsId: const [],
      );

      return await saveUser(user: user, isUpdate: exists);
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // TICKET COLLECTION OPERASYONLARI
  // ========================================

  /// 🎫 Kullanıcıya yeni bir bilet ID'si ekler.
  Future<bool> addTicketToUser(
      final String userId, final String ticketId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'ticketsId': FieldValue.arrayUnion([ticketId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🗑️ Kullanıcı silindiğinde ilişkili biletleri de temizler.
  ///
  Future<bool> deleteUserCompletely(final String userId) async {
    try {
      // 1. Kullanıcının bilet listesini al.
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      final List<dynamic> ticketIds = userDoc.data()?['ticketsId'] ?? [];

      final WriteBatch batch = _firestore.batch();

      // 2. Ticket koleksiyonundaki biletleri sil.
      for (String tId in ticketIds) {
        batch.delete(_firestore.collection(_ticketsCollection).doc(tId));
      }

      // 3. Kullanıcı dokümanını sil.
      batch.delete(_firestore.collection(_usersCollection).doc(userId));

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // READ OPERASYONLARI
  // ========================================

  Future<entity.User?> getUserById(final String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      if (!data.containsKey('_id')) data['_id'] = userId;
      return UserModel.fromFirestore(data).toEntity();
    } catch (e) {
      return null;
    }
  }

  Future<bool> userExists(final String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // YARDIMCI METODLAR
  // ========================================

  Map<String, String> _splitName(final String fullName) {
    if (fullName.isEmpty) return {'firstName': '', 'lastName': ''};
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return {'firstName': parts[0], 'lastName': ''};
    return {
      'firstName': parts.sublist(0, parts.length - 1).join(' '),
      'lastName': parts.last,
    };
  }
}
