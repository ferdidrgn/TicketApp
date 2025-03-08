import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/stage.dart';

class StageService {
  final CollectionReference _stageCollection =
      FirebaseFirestore.instance.collection('Stage');

  // search stage
  Future<List<Stage?>> getSearchStage(final String query) async {
    try {
      final QuerySnapshot snapshot = await _stageCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs.map((final doc) => _mapDocumentToStage(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching stages: $e');
    }
  }

  // all stages
  Future<List<Stage?>> getStages(final isLimit) async {
    try {
      final QuerySnapshot snapshot = isLimit
          ? await _stageCollection.orderBy('_createdAt', descending: true).limit(20).get()
          : await _stageCollection.get();
      return snapshot.docs.map((final doc) => _mapDocumentToStage(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching stages: $e');
    }
  }

  // Fetch a stage by ID
  Future<Stage?> getStageById(final String stageId) async {
    try {
      final QuerySnapshot result = await _stageCollection
          .where('_id', isEqualTo: stageId).limit(1).get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToStage(result.docs.first);
    } catch (error) {
      throw Exception('Error fetching stage: $error');
    }
  }

  // Convert Firestore document to Stage model
  Stage _mapDocumentToStage(final DocumentSnapshot document) {
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
  String _getStringField(final DocumentSnapshot document, final String fieldName) {
    return document[fieldName]?.toString() ?? '';
  }

  List<String> _getListField(final DocumentSnapshot document, final String fieldName) {
    return List<String>.from(document[fieldName] ?? []);
  }
}
