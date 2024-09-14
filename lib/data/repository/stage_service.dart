import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/stage.dart';

class StageService {
  final CollectionReference _stageCollection =
      FirebaseFirestore.instance.collection('Stage');

  Future<List<Stage?>> getSearchStage(String query) async {
    try {
      QuerySnapshot snapshot = await _stageCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs.map((doc) => _mapDocumentToStage(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching stages: $e');
    }
  }

  // Fetch all stages
  Future<List<Stage?>> getStages() async {
    try {
      QuerySnapshot snapshot = await _stageCollection.get();
      return snapshot.docs.map((doc) => _mapDocumentToStage(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching stages: $e');
    }
  }

  // Fetch a stage by ID
  Future<Stage?> getStageById(String stageId) async {
    try {
      QuerySnapshot result = await _stageCollection
          .where('_id', isEqualTo: stageId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToStage(result.docs.first);
    } catch (error) {
      throw Exception('Error fetching stage: $error');
    }
  }

  // Convert Firestore document to Stage model
  Stage _mapDocumentToStage(DocumentSnapshot document) {
    return Stage(
      id: _getStringField(document, '_id'),
      createdAt: _getStringField(document, '_createdAt'),
      updatedAt: _getStringField(document, '_updatedAt'),
      name: _getStringField(document, 'name'),
      imageUrl: _getStringField(document, 'imageUrl'),
      capacity: int.tryParse(_getStringField(document, 'capacity')),
      description: _getStringField(document, 'description'),
      communication: _getStringField(document, 'communication'),
      address: _getStringField(document, 'address'),
      locationLat: double.tryParse(_getStringField(document, 'lat')),
      locationLng: double.tryParse(_getStringField(document, 'long')),
      showsId: _getListField(document, 'showsId'),
    );
  }

  // Utility method for fetching string fields
  String _getStringField(DocumentSnapshot document, String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  List<String> _getListField(DocumentSnapshot document, String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }
}
