import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/stage.dart';

class StageService {
  final CollectionReference _stageCollection =
      FirebaseFirestore.instance.collection('Stage');

  // Fetch all stages
  Future<List<Stage?>> getStages() async {
    try {
      QuerySnapshot snapshot = await _stageCollection.get();
      return snapshot.docs.map((doc) => _mapDocumentToStage(doc)).toList();
    } catch (e) {
      SnackBar(content: Text('Error fetching stages: $e'));
      return [];
    }
  }

  // Fetch a stage by ID
  Future<Stage?> getStageById(String stageId) async {
    try {
      QuerySnapshot result =
          await _stageCollection.where('_id', isEqualTo: stageId).limit(1).get();

      if (result.docs.isEmpty) return null;

      return _mapDocumentToStage(result.docs.first);
    } catch (error) {
      SnackBar(content: Text('Error fetching stage: $error'));
      return null;
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
