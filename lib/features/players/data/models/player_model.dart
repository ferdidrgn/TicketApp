import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String? id;
  final String? createdAt, updatedAt;
  final String? firstName, lastName;
  final String? bio;
  final String? imageUrl;
  final List<String>? nowShowsId;
  final List<String>? oldShowsId;

  const PlayerModel({
    this.createdAt,
    this.updatedAt,
    this.id,
    this.firstName,
    this.lastName,
    this.bio,
    this.imageUrl,
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
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
        nowShowsId:
            (data['nowShowsId'] as List?)?.map((e) => e.toString()).toList(),
        oldShowsId:
            (data['oldShowsId'] as List?)?.map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toFirestore() => {
        '_id': id,
        'firstName': firstName,
        'lastName': lastName,
        'bio': bio,
        'imageUrl': imageUrl,
        'nowShowsId': nowShowsId,
        'oldShowsId': oldShowsId,
      };
}
