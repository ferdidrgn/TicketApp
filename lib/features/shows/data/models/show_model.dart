import 'package:cloud_firestore/cloud_firestore.dart';

class ShowModel {
  final String? id;
  final String? createdAt, updatedAt;
  final String? imageUrl;
  final String? name;
  final String? description;
  final String? duration;
  final String? category;
  final String? teamId;
  final String? type;
  final String? ageLimit;
  final String? eventRule;
  final List<String>? nowPlayersId;
  final List<String>? oldPlayersId;
  final List<String>? eventsId;
  final List<String>? photosShowId;
  final String? trailerYoutubeId;

  const ShowModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.name,
    this.description,
    this.duration,
    this.category,
    this.teamId,
    this.type,
    this.ageLimit,
    this.eventRule,
    this.nowPlayersId,
    this.oldPlayersId,
    this.eventsId,
    this.photosShowId,
    this.trailerYoutubeId,
  });

  /// 🔥 Firestore'dan güvenli okuma
  factory ShowModel.fromFirestore(final Map<String, dynamic> data) => ShowModel(
        id: data['_id'] as String?,
        createdAt: data['_createdAt'] is Timestamp
            ? (data['_createdAt'] as Timestamp).toDate().toIso8601String()
            : data['_createdAt']?.toString(),
        updatedAt: data['_updatedAt'] is Timestamp
            ? (data['_updatedAt'] as Timestamp).toDate().toIso8601String()
            : data['_updatedAt']?.toString(),
        imageUrl: data['imageUrl'] as String?,
        name: data['name'] as String?,
        description: data['description'] as String?,
        duration: data['duration'] as String?,
        category: data['category'] as String?,
        teamId: data['teamId'] as String?,
        type: data['type'] as String?,
        ageLimit: data['ageLimit'] as String?,
        eventRule: data['eventRule'] as String?,
        // Listeleri güvenli cast etme
        eventsId: (data['eventsId'] as List?)
            ?.map((final e) => e.toString())
            .toList(),
        nowPlayersId: (data['nowPlayersId'] as List?)
            ?.map((final e) => e.toString())
            .toList(),
        oldPlayersId: (data['oldPlayersId'] as List?)
            ?.map((final e) => e.toString())
            .toList(),
        photosShowId: (data['photosShowId'] as List?)
            ?.map((final e) => e.toString())
            .toList(),
        trailerYoutubeId: data['trailerYoutubeId'] as String?,
      );

  /// 🔥 Firestore'a yazma
  Map<String, dynamic> toFirestore() => {
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        '_id': id,
        'imageUrl': imageUrl,
        'name': name,
        'description': description,
        'duration': duration,
        'category': category,
        'teamId': teamId,
        'type': type,
        'ageLimit': ageLimit,
        'eventRule': eventRule,
        'eventsId': eventsId,
        'nowPlayersId': nowPlayersId,
        'oldPlayersId': oldPlayersId,
        'photosShowId': photosShowId,
        'trailerYoutubeId': trailerYoutubeId,
      };
}
