import '../../domain/entities/show.dart';

class ShowModel {
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

  const ShowModel({
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

  factory ShowModel.fromFirestore(final Map<String, dynamic>? data) {
    if (data == null) return const ShowModel();
    return ShowModel(
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      id: data['_id'] as String?,
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
  };

  Show toEntity() => Show(
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
    eventsId: eventsId ?? [],
    nowPlayersId: nowPlayersId ?? [],
    oldPlayersId: oldPlayersId ?? [],
    photosShowId: photosShowId ?? [],
  );

  factory ShowModel.fromEntity(final Show show) => ShowModel(
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
