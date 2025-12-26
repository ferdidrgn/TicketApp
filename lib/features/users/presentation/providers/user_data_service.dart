import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart' as entity;

/// 👤 Firestore User Data Service
///
/// Bu servis şunları yapar:
/// 1. ✅ Firestore'da User collection'ını yönetir
/// 2. ✅ User CRUD operasyonlarını gerçekleştirir
/// 3. ✅ User'ın tüm ilişkili verilerini (tickets) siler
/// 4. ✅ Firebase Auth ile senkronizasyon yapar
class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _usersCollection = 'User';
  static const String _ticketsCollection = 'Ticket';

  // ========================================
  // CREATE & UPDATE
  // ========================================

  /// 💾 Save or update user in Firestore
  ///
  /// @param user - User entity to save
  /// @param photoUrl - Optional photo URL (not used in model but kept for compatibility)
  /// @param isUpdate - If true, merges with existing data. If false, creates new
  /// @return bool - Success status
  Future<bool> saveUser({
    required final entity.User user,
    final String? photoUrl,
    final bool isUpdate = false,
  }) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final data = userModel.toFirestore();

      // Remove null values for cleaner Firestore data
      data.removeWhere((final key, final value) => value == null);

      // Add timestamps (Firestore will handle these)
      if (isUpdate)
        data['_updatedAt'] = FieldValue.serverTimestamp();
      else {
        data['_createdAt'] = FieldValue.serverTimestamp();
        data['_updatedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(data, SetOptions(merge: isUpdate));

      return true;
    } catch (e, stack) {
      return false;
    }
  }

  /// 🔄 Sync user from Firebase Auth to Firestore
  ///
  /// Firebase Auth'tan gelen bilgileri Firestore'a senkronize eder.
  /// Yeni kullanıcı oluşturur veya mevcut kullanıcıyı günceller.
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
      // Check if user already exists
      final exists = await userExists(userId);

      final nameParts = _splitName(displayName);

      final user = entity.User(
        id: userId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        firstName: nameParts['firstName'] ?? '',
        lastName: nameParts['lastName'] ?? '',
        imageUrl: photoUrl.isNotEmpty ? photoUrl : '',
        eMail: email.isNotEmpty ? email : '',
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : '',
        role: role,
        age: 0,
        city: '',
        isPhoneActive: isPhoneActive,
        fcmToken: '',
        favoriteShows: const [],
        favoriteStages: const [],
        favoritePlayers: const [],
        ticketsId: const [],
      );

      return await saveUser(
        user: user,
        photoUrl: photoUrl,
        isUpdate: exists, // Update if exists, create if not
      );
    } catch (e, stack) {
      return false;
    }
  }

  // ========================================
  // READ
  // ========================================

  /// 📖 Get user by ID
  ///
  /// @param userId - User ID to fetch
  /// @return User entity or null if not found
  Future<entity.User?> getUserById(final String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;


      // Add document ID to data if not present
      if (!data.containsKey('_id')) data['_id'] = userId;

      final userModel = UserModel.fromFirestore(data);

      return userModel.toEntity();
    } catch (e, stack) {
      return null;
    }
  }

  /// 📖 Check if user exists
  ///
  /// @param userId - User ID to check
  /// @return bool - True if exists, false otherwise
  Future<bool> userExists(final String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 📖 Get user's ticket IDs
  ///
  /// @param userId - User ID
  /// @return List of ticket IDs
  Future<List<String>> getUserTicketIds(final String userId) async {
    try {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data();
      if (userData == null || userData['ticketsId'] == null) return [];

      // Handle both List<String?> and List<dynamic>
      final ticketsIdData = userData['ticketsId'];
      if (ticketsIdData is! List) return [];

      return ticketsIdData
          .whereType<String>() // Filter only String types
          .where((final id) => id.isNotEmpty)
          .toList();
    } catch (e, stack) {
      return [];
    }
  }

  // ========================================
  // DELETE
  // ========================================

  /// 🗑️ Delete user and all related data
  ///
  /// Bu metod şunları siler:
  /// 1. User'ın tüm ticket'larını (ticketsId array'inden)
  /// 2. User document'ını
  ///
  /// ⚠️ Bu işlem geri alınamaz!
  Future<bool> deleteUserCompletely(final String userId) async {
    try {

      // 1. Get user's ticket IDs
      final ticketIds = await getUserTicketIds(userId);

      // 2. Delete all user's tickets in a batch
      if (ticketIds.isNotEmpty) {

        final batch = _firestore.batch();
        for (final ticketId in ticketIds) {
          final ticketRef =
              _firestore.collection(_ticketsCollection).doc(ticketId);
          batch.delete(ticketRef);
        }

        await batch.commit();
      }

      // 3. Delete user document
      await _firestore.collection(_usersCollection).doc(userId).delete();
      return true;
    } catch (e, stack) {
      return false;
    }
  }

  /// 🗑️ Delete only user document (not tickets)
  ///
  /// Sadece User document'ını siler, ticket'ları silmez.
  /// Genellikle kullanılmaz, deleteUserCompletely() tercih edilir.
  Future<bool> deleteUserDocument(final String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
      return true;
    } catch (e, stack) {
      return false;
    }
  }

  // ========================================
  // UPDATE SPECIFIC FIELDS
  // ========================================

  /// 🔄 Update specific user fields
  ///
  /// @param userId - User ID
  /// @param fields - Map of fields to update
  /// @return bool - Success status
  Future<bool> updateUserFields(
      final String userId, final Map<String, dynamic> fields) async {
    try {
      // Add update timestamp
      fields['_updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_usersCollection).doc(userId).update(fields);

      return true;
    } catch (e, stack) {
      return false;
    }
  }

  /// 📋 Add ticket ID to user
  Future<bool> addTicketToUser(
      final String userId, final String ticketId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'ticketsId': FieldValue.arrayUnion([ticketId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e, stack) {
      return false;
    }
  }

  /// 🗑️ Remove ticket ID from user
  Future<bool> removeTicketFromUser(
      final String userId, final String ticketId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'ticketsId': FieldValue.arrayRemove([ticketId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e, stack) {
      return false;
    }
  }

  /// ❤️ Add favorite show
  Future<bool> addFavoriteShow(final String userId, final String showId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'favoriteShows': FieldValue.arrayUnion([showId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 💔 Remove favorite show
  Future<bool> removeFavoriteShow(
      final String userId, final String showId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'favoriteShows': FieldValue.arrayRemove([showId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ❤️ Add favorite stage
  Future<bool> addFavoriteStage(
      final String userId, final String stageId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'favoriteStages': FieldValue.arrayUnion([stageId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 💔 Remove favorite stage
  Future<bool> removeFavoriteStage(
      final String userId, final String stageId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'favoriteStages': FieldValue.arrayRemove([stageId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ❤️ Add favorite player
  Future<bool> addFavoritePlayer(
      final String userId, final String playerId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'favoritePlayers': FieldValue.arrayUnion([playerId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 💔 Remove favorite player
  Future<bool> removeFavoritePlayer(
      final String userId, final String playerId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'favoritePlayers': FieldValue.arrayRemove([playerId]),
        '_updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // UTILITY
  // ========================================

  /// Split full name into first and last name
  Map<String, String> _splitName(final String fullName) {
    if (fullName.isEmpty) return {'firstName': '', 'lastName': ''};

    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return {'firstName': parts[0], 'lastName': ''};

    return {
      'firstName': parts.sublist(0, parts.length - 1).join(' '),
      'lastName': parts.last,
    };
  }

  /// Get collection reference (for advanced queries)
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection(_usersCollection);
}
