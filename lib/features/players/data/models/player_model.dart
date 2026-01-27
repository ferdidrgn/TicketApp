import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String? id,
      createdAt,
      updatedAt,
      firstName,
      lastName,
      imageUrl,
      bio,
      quote;
  final List<dynamic>? achievements;
  final List<dynamic>? collaborations;
  final List<String>? nowShowsId, oldShowsId;

  const PlayerModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.firstName,
    this.lastName,
    this.imageUrl,
    this.bio,
    this.quote,
    this.achievements,
    this.collaborations,
    this.nowShowsId,
    this.oldShowsId,
  });

  factory PlayerModel.fromFirestore(final Map<String, dynamic> data) =>
      PlayerModel(
        id: data['_id'] as String?,
        firstName: data['firstName'] as String?,
        lastName: data['lastName'] as String?,
        bio: data['bio'] as String?,
        imageUrl: data['imageUrl'] as String?,
        quote: data['quote'] as String?,
        achievements: data['achievements'] as List?,
        collaborations: data['collaborations'] as List?,
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
        nowShowsId:
            (data['nowShowsId'] as List?)?.map((final e) => e.toString()).toList(),
        oldShowsId:
            (data['oldShowsId'] as List?)?.map((final e) => e.toString()).toList(),
      );

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'firstName': firstName,
        'lastName': lastName,
        'bio': bio,
        'quote': quote,
        'achievements': achievements,
        'collaborations': collaborations,
        'imageUrl': imageUrl,
        'nowShowsId': nowShowsId,
        'oldShowsId': oldShowsId,
      };
}
