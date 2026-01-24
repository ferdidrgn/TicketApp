import '../../domain/entities/stage.dart';
import '../models/stage_model.dart';

extension StageModelMapper on StageModel {
  Stage toEntity() => Stage(
        id: id ?? '',
        name: name ?? 'İsimsiz Sahne',
        imageUrl: imageUrl ?? '',
        capacity: capacity ?? 'Kapasite bilgisi yok',
        description: description ?? '',
        communication: communication ?? '',
        address: address ?? '',
        locationLat: locationLat ?? 0.0,
        locationLng: locationLng ?? 0.0,
        createdAt: createdAt ?? '',
        updatedAt: updatedAt ?? '',
        showsId: showsId ?? [],
      );
}

extension StageEntityMapper on Stage {
  StageModel toModel() => StageModel(
        id: id,
        name: name,
        imageUrl: imageUrl,
        capacity: capacity,
        description: description,
        communication: communication,
        address: address,
        locationLat: locationLat,
        locationLng: locationLng,
        createdAt: createdAt,
        updatedAt: updatedAt,
        showsId: showsId,
      );
}
