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
        quote: quote ?? "Sahne hayattır.",
        // Alan yoksa varsayılan metin
        collaborations:
            collaborations?.map((final e) => e.toString()).toList() ?? [],
        // Yoksa boş liste
        achievements: _safeMapAchievements(achievements),
        // Hata almayan özel fonksiyon
        nowShowsId: nowShowsId ?? [],
        oldShowsId: oldShowsId ?? [],
      );

  // 🛡️ Bu fonksiyon Firebase'de veri bozuk olsa bile uygulamayı kurtarır
  List<Map<String, String>> _safeMapAchievements(final List<dynamic>? data) {
    if (data == null || data.isEmpty) return [];
    try {
      return data.whereType<Map>().map((final e) {
        return {
          'year': e['year']?.toString() ?? '',
          'title': e['title']?.toString() ?? '',
          'detail': e['detail']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return []; // Bir şeyler çok yanlış gitse bile boş liste dön, uygulama kilitlenmesin
    }
  }
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
        quote: quote,
        collaborations: collaborations,
        achievements: achievements,
        nowShowsId: nowShowsId,
        oldShowsId: oldShowsId,
      );
}
