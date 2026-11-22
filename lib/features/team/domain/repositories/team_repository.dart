import '../entities/team_manager_entities.dart';

/// Ekip yöneticisi deposu — yetki/kapsam denetimi SUNUCUDADIR
/// (`functions/src/team.js`); bu arayüz yalnız sunucunun verdiği veriyi
/// taşır. Hatalar `TeamException` olarak fırlatılır
/// (`team_remote_data_source.dart`).
abstract class TeamRepository {
  /// Kullanıcının AKTİF yönetici olduğu ekipler + oyunları + yaklaşan
  /// seansları. Yetkisiz kullanıcıda boş liste döner (hata değil).
  Future<List<TeamManagerTeam>> getMyManagedTeams();

  /// Bir seansa bildirim göndermeden ÖNCE önizleme: kaç kişiye ulaşılır,
  /// hangi şablonlar kullanılabilir, (şablon seçiliyse) üretilmiş metin.
  Future<NotifyPreview> notifyPreview({
    required final String eventId,
    final String? template,
    final Map<String, int>? params,
    final String? title,
    final String? body,
  });

  /// Önizlemesi onaylanmış bildirimi gönderir. [requestId] aynı isteğin
  /// yinelenmesini engeller (8-64 karakter, harf/rakam/_/-).
  Future<NotifySendResult> sendNotification({
    required final String eventId,
    required final String requestId,
    final String? template,
    final Map<String, int>? params,
    final String? title,
    final String? body,
  });

  /// Kendi ekip(ler)inin oyun/seans satış-doluluk-giriş özeti.
  /// [teamId] verilmezse yönetilen TÜM ekipler döner.
  Future<List<TeamStatsShow>> getTeamStats({final String? teamId});
}
