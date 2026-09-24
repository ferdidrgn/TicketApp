import 'package:equatable/equatable.dart';

class Show extends Equatable {
  final String id;
  final String createdAt, updatedAt;

  final String name;
  final String description;
  final String imageUrl;

  final String duration;
  final String category;
  final String type;
  final String ageLimit;
  final String eventRule;

  final String teamId;

  final List<String> eventsId;
  final List<String> nowPlayersId;
  final List<String> oldPlayersId;
  final List<String> photosShowId;

  /// Biletlerin bu uygulama içinde değil, harici bir platformda satıldığı
  /// oyunlar için o platformun bilet/etkinlik sayfası URL'i. Boşsa bilet
  /// akışı her zamanki gibi uygulama içi (koltuk seçimi/Event) — dolu
  /// olmak, ayrı bir "durum" bayrağı tutmak yerine, bu oyunun harici bir
  /// oyun/bilet kaynağı olduğunun TEK doğruluk kaynağıdır (bkz.
  /// `show_provider.dart`'taki "isActive" bayrağı eklenmeme gerekçesiyle
  /// aynı prensip: senkron tutulması gereken ayrı bir alan yerine, zaten
  /// var olan veriden türetilen tek kaynak).
  final String externalTicketUrl;

  bool get hasExternalTicketing => externalTicketUrl.trim().isNotEmpty;

  /// Son 21 gün içinde eklenmiş mi — "YENİ" rozeti için TEK doğruluk
  /// kaynağı `createdAt`'ın kendisi; ayrı, senkron tutulması gereken bir
  /// "isNew"/"isTrend" alanı YOK (aynı `hasExternalTicketing` prensibi).
  bool get isRecentlyAdded {
    final created = DateTime.tryParse(createdAt);
    if (created == null) return false;
    return DateTime.now().difference(created).inDays <= 21;
  }

  const Show({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.duration,
    required this.category,
    required this.type,
    required this.ageLimit,
    required this.eventRule,
    required this.teamId,
    required this.eventsId,
    required this.nowPlayersId,
    required this.oldPlayersId,
    required this.photosShowId,
    this.externalTicketUrl = '',
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        name,
        description,
        imageUrl,
        duration,
        category,
        type,
        ageLimit,
        eventRule,
        teamId,
        eventsId,
        nowPlayersId,
        oldPlayersId,
        photosShowId,
        externalTicketUrl,
      ];
}
