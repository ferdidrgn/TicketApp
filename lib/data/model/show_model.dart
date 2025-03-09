import '../../domain/entities/show.dart';

class ShowModel {
  final String createdAt;
  final String updatedAt;
  final String id;
  final String imageUrl;
  final String name;
  final String description;
  final String duration;
  final String category;
  final String teamId;
  final String type;
  final String ageLimit;
  final String eventRule;
  final List<String> nowPlayersId;
  final List<String> oldPlayersId;
  final List<String> eventsId;
  final List<String> photosShowId;

  const ShowModel({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.duration,
    required this.category,
    required this.type,
    required this.teamId,
    required this.ageLimit,
    required this.eventRule,
    required this.eventsId,
    required this.nowPlayersId,
    required this.oldPlayersId,
    required this.photosShowId,
  });

  factory ShowModel.fromFirestore(final Map<String, dynamic> data) {
    return ShowModel(
      createdAt: data['_createdAt'] ?? '',
      updatedAt: data['_updatedAt'] ?? '',
      id: data['_id'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      duration: data['duration'] ?? '',
      category: data['category'] ?? '',
      teamId: data['teamId'] ?? '',
      type: data['type'] ?? '',
      ageLimit: data['ageLimit'] ?? '',
      eventRule: data['eventRule'] ?? '',
      eventsId: List<String>.from(data['eventsId'] ?? []),
      nowPlayersId: List<String>.from(data['nowPlayersId'] ?? []),
      oldPlayersId: List<String>.from(data['oldPlayersId'] ?? []),
      photosShowId: List<String>.from(data['photosShowId'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
    };
  }

  Show toEntity() {
    return Show(
      createdAt: createdAt,
      updatedAt: updatedAt,
      id: id,
      imageUrl: imageUrl,
      name: name,
      description: description,
      duration: duration,
      category: category,
      teamId: teamId,
      type: type,
      ageLimit: ageLimit,
      eventRule: eventRule,
      eventsId: eventsId,
      nowPlayersId: nowPlayersId,
      oldPlayersId: oldPlayersId,
      photosShowId: photosShowId,
    );
  }

  factory ShowModel.fromEntity(final Show show) {
    return ShowModel(
      createdAt: show.createdAt,
      updatedAt: show.updatedAt,
      id: show.id,
      imageUrl: show.imageUrl,
      name: show.name,
      description: show.description,
      duration: show.duration,
      category: show.category,
      teamId: show.teamId,
      type: show.type,
      ageLimit: show.ageLimit,
      eventRule: show.eventRule,
      eventsId: show.eventsId,
      nowPlayersId: show.nowPlayersId,
      oldPlayersId: show.oldPlayersId,
      photosShowId: show.photosShowId,
    );
  }
}
