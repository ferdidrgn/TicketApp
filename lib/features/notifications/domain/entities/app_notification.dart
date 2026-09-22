import 'package:equatable/equatable.dart';

/// Bildirim türleri.
/// Şimdilik sadece bilet/rezervasyon onayı üretiliyor; ileride hatırlatma,
/// iptal, kampanya vb. türler eklenmek istenirse buraya eklenmesi yeterli.
enum NotificationType {
  bookingConfirmation,
  unknown;

  static NotificationType fromString(final String? value) =>
      NotificationType.values.firstWhere((final e) => e.name == value,
          orElse: () => NotificationType.unknown);
}

/// Uygulama içi ve push bildirimlerinin ortak veri modeli.
/// Firestore'da düz (flat) bir koleksiyonda `userId` alanına göre sorgulanır.
class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;

  final String showId;
  final String showName;

  /// "dd.MM.yyyy, HH:mm" formatında etkinlik tarihi.
  /// bkz. [DateFormatter] (lib/core/util/date_formatter.dart) — Event.date ile
  /// AYNI formatı kullanır ki geçmiş/gelecek kontrolü tek bir yerden yapılsın.
  final String eventDate;

  final List<String> seats;
  final bool isRead;

  /// ISO 8601 - Ticket.createdAt ile aynı üretim biçimi (DateTime.now().toIso8601String()).
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.showId,
    required this.showName,
    required this.eventDate,
    required this.seats,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({
    final String? id,
    final bool? isRead,
  }) =>
      AppNotification(
        id: id ?? this.id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        showId: showId,
        showName: showName,
        eventDate: eventDate,
        seats: seats,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        type,
        showId,
        showName,
        eventDate,
        seats,
        isRead,
        createdAt,
      ];
}
