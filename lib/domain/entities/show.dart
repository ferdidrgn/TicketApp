import 'package:equatable/equatable.dart';

class Show extends Equatable {
  final String? createdAt;
  final String? updatedAt;
  final String? id;
  final String? imageUrl;
  final String? name;
  final String? description;
  final String? duration;
  final String? category;
  final String? teamId;
  final String? type;
  final String? ageLimit;
  final String? eventRule;
  final List<String?>? nowPlayersId;
  final List<String?>? oldPlayersId;
  final List<String?>? eventsId;
  final List<String?>? photosShowId;

  const Show({
    this.createdAt,
    this.updatedAt,
    this.id,
    this.imageUrl,
    this.name,
    this.description,
    this.duration,
    this.category,
    this.type,
    this.teamId,
    this.ageLimit,
    this.eventRule,
    this.eventsId,
    this.nowPlayersId,
    this.oldPlayersId,
    this.photosShowId,
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

  factory Show.fromMap(final Map<String, dynamic>? data) {
    if (data == null) return const Show();
    return Show(
      id: data['_id'] as String?,
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      imageUrl: data['imageUrl'] as String?,
      name: data['name'] as String?,
      description: data['description'] as String?,
      duration: data['duration'] as String?,
      category: data['category'] as String?,
      teamId: data['teamId'] as String?,
      type: data['type'] as String?,
      ageLimit: data['ageLimit'] as String?,
      eventRule: data['eventRule'] as String?,
      eventsId: (data['eventsId'] as List?)?.map((final e) => e as String?).toList(),
      nowPlayersId: (data['nowPlayersId'] as List?)?.map((final e) => e as String?).toList(),
      oldPlayersId: (data['oldPlayersId'] as List?)?.map((final e) => e as String?).toList(),
      photosShowId: (data['photosShowId'] as List?)?.map((final e) => e as String?).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
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
