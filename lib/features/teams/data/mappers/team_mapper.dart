import '../../domain/entities/team.dart';
import '../models/team_model.dart';

extension TeamModelMapper on TeamModel {
  /// Model -> Entity (Okuma)
  Team toEntity() => Team(
        id: id ?? '',
        createdAt: createdAt ?? '',
        updatedAt: updatedAt ?? '',
        name: name ?? 'İsimsiz Takım',
        description: description ?? 'Açıklama bulunamadı.',
        imageUrl: imageUrl ?? 'https://example.com/default-image.png',
        photosId: photosId?.whereType<String>().toList() ?? [],
        showsId: showsId?.whereType<String>().toList() ?? [],
      );
}

extension TeamEntityMapper on Team {
  /// Entity -> Model (Yazma)
  TeamModel toModel() => TeamModel(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        name: name,
        description: description,
        imageUrl: imageUrl,
        photosId: photosId,
        showsId: showsId,
      );
}
