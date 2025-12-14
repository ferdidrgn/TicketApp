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
    required this.teamId,
    required this.type,
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

  factory Show.fromMap(final Map<String, dynamic>? data) => Show(
        id: data?['_id'] as String? ?? '0',
        createdAt: data?['_createdAt'] as String? ?? 'Tarih bulunamadı',
        updatedAt: data?['_updatedAt'] as String? ?? 'Tarih bulunamadı',
        name: data?['name'] as String? ?? 'İsimsiz Takım',
        description: data?['description'] as String? ?? 'Açıklama bulunamadı.',
        duration: data?['duration'] as String? ?? 'Süre bulunamadı.',
        category: data?['category'] as String? ?? 'Kategori bulunamadı.',
        teamId: data?['teamId'] as String? ?? '0',
        type: data?['type'] as String? ?? 'Tür bulunamadı.',
        ageLimit: data?['ageLimit'] as String? ?? 'Yaş limiti bulunamadı.',
        eventRule: data?['eventRule'] as String? ?? 'Kurallar bulunamadı.',
        imageUrl: data?['imageUrl'] as String? ??
            'https://example.com/default-image.png',
        photosShowId: (data?['photosShowId'] as List<dynamic>?)
                ?.map((final e) => e as String)
                .toList() ??
            [],
        eventsId: (data?['eventsId'] as List<dynamic>?)
                ?.map((final e) => e as String)
                .toList() ??
            [],
        nowPlayersId: (data?['nowPlayersId'] as List<dynamic>?)
                ?.map((final e) => e as String)
                .toList() ??
            [],
        oldPlayersId: (data?['oldPlayersId'] as List<dynamic>?)
                ?.map((final e) => e as String)
                .toList() ??
            [],
      );

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
