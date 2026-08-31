import '../../domain/entities/show.dart';
import '../models/show_model.dart';

extension ShowModelMapper on ShowModel {
  /// Model -> Entity (Okuma)
  Show toEntity() => Show(
        id: id ?? '',
        createdAt: createdAt ?? '',
        updatedAt: updatedAt ?? '',
        name: name ?? 'İsimsiz Etkinlik',
        description: description ?? '',
        duration: duration ?? '',
        category: category ?? '',
        teamId: teamId ?? '',
        type: type ?? '',
        imageUrl: imageUrl ?? '',
        ageLimit: ageLimit ?? '',
        eventRule: eventRule ?? '',
        eventsId: eventsId?.whereType<String>().toList() ?? [],
        nowPlayersId: nowPlayersId?.whereType<String>().toList() ?? [],
        oldPlayersId: oldPlayersId?.whereType<String>().toList() ?? [],
        photosShowId: photosShowId?.whereType<String>().toList() ?? [],
        trailerYoutubeId: trailerYoutubeId,
      );
}

extension ShowEntityMapper on Show {
  /// Entity -> Model (Yazma/Güncelleme)
  ShowModel toModel() => ShowModel(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
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
        trailerYoutubeId: trailerYoutubeId,
      );
}
