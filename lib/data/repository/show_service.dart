import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/show.dart';

class ShowService {
  final CollectionReference _showCollection =
      FirebaseFirestore.instance.collection('Show');

  // Oyunları getiren fonksiyon
  Future<List<Map<String, dynamic>>> getShows() async {
    List<Map<String, dynamic>> shows = [];
    try {
      QuerySnapshot snapshot = await _showCollection.get();
      for (var doc in snapshot.docs) {
        shows.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting games: $e');
    }
    return shows;
  }

  // Show ID ile gösterileri getiren fonksiyon
  Future<Show?> getShowById(String showId) async {
    try {
      QuerySnapshot result =
          await _showCollection.where('_id', isEqualTo: showId).get();

      if (result.docs.isEmpty) {
        return null;
      } else {
        return getAllHashMap(result);
      }
    } catch (error) {
      return null;
    }
  }

// Show kaydetme fonksiyonu
  Future<void> saveShow(Show show) async {

    // Firestore'da otomatik bir ID ile bir belge referansı oluştur
    DocumentReference docRef = _showCollection.doc();

    await docRef.set({
      '_id': docRef.id,
      // Otomatik ID ekleniyor
      '_createdAt': FieldValue.serverTimestamp(),
      '_updatedAt': FieldValue.serverTimestamp(),
      'name': show.name,
      'description': show.description,
      'imageUrl': show.imageUrl,
      'ageLimit': show.ageLimit,
      'eventRule': show.eventRule,
      'players': show.playersId,
      'events': show.eventsId,
      //'gamePhotos': show.gamePhotos,
    });
  }

// Show güncelleme fonksiyonu
  Future<void> updateShow(
      String showId, Map<String, dynamic> updatedData) async {
    await _showCollection.doc(showId).update({
      ...updatedData, // Güncellenen veriler
      '_updatedAt': FieldValue.serverTimestamp(), // Güncelleme zamanı
    });
  }

  Show? getAllHashMap(QuerySnapshot result) {
    final document = result.docs.first;
    String createdAt =
        document['_createdAt'] != null ? document['_createdAt'].toString() : '';
    String updateAt =
        document['_updateAt'] != null ? document['_updateAt'].toString() : '';
    String id = document['_id'] != null ? document['_id'] as String : '';
    String imgUrl =
        document['imageUrl'] != null ? document['imageUrl'] as String : '';
    String name = document['name'] != null ? document['name'] as String : '';
    String description = document['description'] != null
        ? document['description'] as String: '';
    String ageLimit =
        document['ageLimit'] != null ? document['ageLimit'] as String : '';
    String eventRule =
        document['eventRule'] != null ? document['eventRule'] as String : '';

    List<dynamic> playerIdRaw = document['playersId'] != null
        ? document['playersId'] as List<dynamic>: [];
    List<String> playerId =
        playerIdRaw.isNotEmpty ? List<String>.from(playerIdRaw) : [];

    List<dynamic> eventsIdRaw = document['eventsId'] != null
        ? document['eventsId'] as List<dynamic>: [];
    List<String> eventsId =
        eventsIdRaw.isNotEmpty ? List<String>.from(eventsIdRaw) : [];

    return Show(
      createdAt: createdAt,
      updateAt: updateAt,
      id: id,
      imageUrl: imgUrl,
      name: name,
      description: description,
      ageLimit: ageLimit,
      eventRule: eventRule,
      playersId: playerId,
      eventsId: eventsId,
    );
  }
}
