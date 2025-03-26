import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String createdAt;
  final String updatedAt;
  final String id;
  final String firstName;
  final String lastName;
  final String bio;
  final String imageUrl;
  final List<String> nowShowsId;
  final List<String> oldShowsId;

  const Player({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.imageUrl,
    required this.nowShowsId,
    required this.oldShowsId,
  });

  @override
  List<Object?> get props => [
        createdAt,
        updatedAt,
        id,
        firstName,
        lastName,
        bio,
        imageUrl,
        nowShowsId,
        oldShowsId,
      ];

  factory Player.fromMap(final Map<String, dynamic>? data) => Player(
        id: data?['_id'] as String? ?? '0',
        createdAt: data?['_createdAt'] as String? ?? 'Tarih bulunamadı',
        updatedAt: data?['_updatedAt'] as String? ?? 'Tarih bulunamadı',
        firstName: data?['firstName'] as String? ?? 'İsimsiz Takım',
        lastName: data?['lastName'] as String? ?? 'İsimsiz Takım',
        bio: data?['bio'] as String? ?? 'Açıklama bulunamadı.',
        imageUrl: data?['imageUrl'] as String? ??
            'https://example.com/default-image.png',
        nowShowsId: (data?['nowShowsId'] as List<dynamic>?)
                ?.map((final e) => e as String)
                .toList() ??
            [],
        oldShowsId: (data?['oldShowsId'] as List<dynamic>?)
                ?.map((final e) => e as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
        '_id': id,
        '_createdAt': createdAt,
        '_updatedAt': updatedAt,
        'imageUrl': imageUrl,
        'firstName': firstName,
        'lastName': lastName,
        'bio': bio,
        'nowShowsId': nowShowsId,
        'oldShowsId': oldShowsId,
      };
}
