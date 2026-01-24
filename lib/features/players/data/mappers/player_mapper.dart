import '../../domain/entities/player.dart';
import '../models/player_model.dart';

extension PlayerModelMapper on PlayerModel {
  Player toEntity() => Player(
      id: id ?? '',
      createdAt: createdAt ?? '',
      updatedAt: updatedAt ?? '',
      firstName: firstName ?? 'İsimsiz',
      lastName: lastName ?? 'Oyuncu',
      bio: bio ?? 'Bio bulunamadı.',
      imageUrl: imageUrl ?? 'https://example.com/default-image.png',
      nowShowsId: nowShowsId ?? [],
      oldShowsId: oldShowsId ?? [],
    );
}

extension PlayerEntityMapper on Player {
  PlayerModel toModel() => PlayerModel(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      firstName: firstName,
      lastName: lastName,
      bio: bio,
      imageUrl: imageUrl,
      nowShowsId: nowShowsId,
      oldShowsId: oldShowsId,
    );
}
