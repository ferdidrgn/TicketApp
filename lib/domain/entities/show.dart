import 'package:equatable/equatable.dart';

class Show extends Equatable {
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

  const Show({
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

  @override
  List<Object?> get props => [
    createdAt,
    updatedAt,
    id,
    imageUrl,
    name,
    description,
    duration,
    category,
    type,
    teamId,
    ageLimit,
    eventRule,
    eventsId,
    nowPlayersId,
    oldPlayersId,
    photosShowId,
  ];

  factory Show.fromMap(final Map<String, dynamic> data, String docId) {
    return Show(
      createdAt: data['_createdAt'] ?? '',
      updatedAt: data['_updatedAt'] ?? '',
      id: docId,
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

  Map<String, dynamic> toMap() {
    return {
      '_createdAt': createdAt,
      '_updatedAt': updatedAt,
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
}
