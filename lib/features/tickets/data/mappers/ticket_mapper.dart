import '../../domain/entities/ticket.dart';
import '../models/ticket_model.dart';

extension TicketModelMapper on TicketModel {
  /// Model -> Entity (Okuma)
  Ticket toEntity() => Ticket(
        id: id ?? '',
        createdAt: createdAt ?? '',
        updatedAt: updatedAt ?? '',
        customerId: customerId ?? '',
        showId: showId ?? '',
        stageId: stageId ?? '',
        eventId: eventId ?? '',
        orderMethod: orderMethod ?? '',
        orderPrice: orderPrice ?? '0',
        buySeats: buySeats?.whereType<String>().toList() ?? [],
        isPast: isPast ?? false,
        showName: showName ?? '',
        showImageUrl: showImageUrl ?? '',
        stageName: stageName ?? '',
        eventDate: eventDate ?? '',
        paymentStatus: paymentStatus ?? '',
        usedAt: usedAt ?? '',
        cancelledAt: cancelledAt ?? '',
      );
}
