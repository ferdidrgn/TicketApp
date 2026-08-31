import '../../domain/entities/event.dart';
import '../models/event_model.dart';

extension EventModelMapper on EventModel {
  Event toEntity() => Event(
        id: id ?? '',
        stageId: stageId ?? '',
        showId: showId ?? '',
        date: date ?? 'Tarih bulunamadı',
        price: price ?? '0',
        seats: seats ?? {},
        sponsors: sponsors ?? const [],
      );
}

extension EventEntityMapper on Event {
  EventModel toModel() => EventModel(
        id: id,
        stageId: stageId,
        showId: showId,
        date: date,
        price: price,
        seats: seats,
        sponsors: sponsors,
      );
}
