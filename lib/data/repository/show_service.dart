import 'package:cloud_firestore/cloud_firestore.dart';

class ShowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _showCollection = FirebaseFirestore.instance.collection('Show');

  // Oyunları getiren fonksiyon
  Future<List<Map<String, dynamic>>> getShows() async {
    List<Map<String, dynamic>> shows = [];
    try {
      QuerySnapshot snapshot = await _firestore.collection('Show').get();
      for (var doc in snapshot.docs) {
        shows.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting games: $e');
    }
    return shows;
  }

  // Show ID ile gösterileri getiren fonksiyon
  Future<Map<String, dynamic>?> getShowById(String showId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('Show').doc(showId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting game: $e');
      return null;
    }
  }

  // Show kaydetme fonksiyonu
  Future<void> saveShow(
      String title,
      String description,
      String imageUrl,
      String ageRule,
      String eventRule,
      List<String> playerIds,
      List<Map<String, dynamic>> events,
      List<String> gamePhotos) async {

    // Firestore'da otomatik bir ID ile bir belge referansı oluştur
    DocumentReference docRef = _showCollection.doc();

    await docRef.set({
      'id': docRef.id, // Otomatik ID ekleniyor
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'ageRule': ageRule,
      'eventRule': eventRule,
      'players': playerIds,
      'events': events,
      'gamePhotos': gamePhotos,
      'createdAt': FieldValue.serverTimestamp(), // Sunucu zamanı kullanılarak oluşturulma zamanı
      'updatedAt': FieldValue.serverTimestamp(), // İlk başta createdAt ile aynı olacak
    });
  }

  // Show güncelleme fonksiyonu
  Future<void> updateShow(String showId, Map<String, dynamic> updatedData) async {
    await _showCollection.doc(showId).update({
      ...updatedData, // Güncellenen veriler
      'updatedAt': FieldValue.serverTimestamp(), // Güncelleme zamanı
    });
  }
}
