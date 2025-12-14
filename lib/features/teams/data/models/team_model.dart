import '../../domain/entities/team.dart';

class TeamModel {
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final String? name;
  final String? description;
  final String? imageUrl;
  final List<String?>? photosId;
  final List<String?>? showsId;

  const TeamModel({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.description,
    this.imageUrl,
    this.photosId,
    this.showsId,
  });

  factory TeamModel.fromFirestore(final Map<String, dynamic>? data){
    if(data == null) return const TeamModel();
    return TeamModel(
      createdAt: data['_createdAt'] as String?,
      updatedAt: data['_updatedAt'] as String?,
      id: data['_id'] as String?,
      name: data['name'] as String?,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      photosId: (data['photosId']  as List?)?.map((final e) => e as String?).toList(),
      showsId: (data['showsId']  as List?)?.map((final e) => e as String?).toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    '_createdAt': createdAt,
    '_updatedAt': updatedAt,
    '_id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'photosId': photosId,
    'showsId': showsId,
  };

  Team toEntity() => Team(
    id: id ?? '0',
    createdAt: createdAt ?? 'Tarih bulunamadı',
    updatedAt: updatedAt ?? 'Tarih bulunamadı',
    imageUrl: imageUrl ?? 'https://example.com/default-image.png',
    name: name ?? 'İsim bulunamadı',
    description: description ?? 'Açıklama bulunamadı',
    photosId: photosId?.where((final e) => e != null).map((final e) => e!).toList() ?? [],
    showsId: showsId?.where((final e) => e != null).map((final e) => e!).toList() ?? [],
  );

  factory TeamModel.fromEntity(final Team team) => TeamModel(
    id: team.id,
    createdAt: team.createdAt,
    updatedAt: team.updatedAt,
    name: team.name,
    description: team.description,
    imageUrl: team.imageUrl,
    photosId: team.photosId,
    showsId: team.showsId,
  );
}
