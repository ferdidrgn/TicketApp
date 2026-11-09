import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/team_remote_data_source.dart';
import '../../data/repositories/team_repository_impl.dart';
import '../../domain/entities/team_manager_entities.dart';
import '../../domain/repositories/team_repository.dart';

// 🔧 KODLAMA NOTU: `build_runner` bu sandbox'ta çalışmıyor — bu dosya
// klasik (codegen'siz) `Provider`/`FutureProvider.family` API'si kullanır
// (bkz. CLAUDE.md, `show_provider.dart` > `eventsByShowIdsProvider`).

final teamRemoteDataSourceProvider = Provider<TeamRemoteDataSource>(
    (final ref) => TeamRemoteDataSourceImpl());

final teamRepositoryProvider = Provider<TeamRepository>(
    (final ref) => TeamRepositoryImpl(ref.watch(teamRemoteDataSourceProvider)));

/// Kullanıcının yönettiği ekipler + oyunlar + yaklaşan seanslar.
/// Yetkisiz kullanıcıda boş liste döner (hata değil — sunucunun sözleşmesi).
final myManagedTeamsProvider = FutureProvider<List<TeamManagerTeam>>(
    (final ref) => ref.watch(teamRepositoryProvider).getMyManagedTeams());

/// Seçili seansın bildirim önizlemesi. `requestKey`, aynı seans için önizleme
/// SIRASINDA şablon/metin değiştikçe de yeniden hesaplanabilsin diye
/// `eventId|template|params|title|body` birleşiminden kurulur (web'in her
/// seçimde `teamNotifyPreview`'ı yeniden çağırmasıyla aynı davranış).
class NotifyPreviewRequest {
  final String eventId;
  final String? template;
  final Map<String, int>? params;
  final String? title;
  final String? body;

  const NotifyPreviewRequest({
    required this.eventId,
    this.template,
    this.params,
    this.title,
    this.body,
  });

  @override
  bool operator ==(final Object other) =>
      other is NotifyPreviewRequest &&
      other.eventId == eventId &&
      other.template == template &&
      _mapEquals(other.params, params) &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(
      eventId, template, title, body, params == null ? 0 : params!.length);

  static bool _mapEquals(final Map<String, int>? a, final Map<String, int>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

final notifyPreviewProvider = FutureProvider.autoDispose
    .family<NotifyPreview, NotifyPreviewRequest>((final ref, final req) =>
        ref.watch(teamRepositoryProvider).notifyPreview(
              eventId: req.eventId,
              template: req.template,
              params: req.params,
              title: req.title,
              body: req.body,
            ));

/// Kendi ekip(ler)inin satış/doluluk/giriş özeti. `null` -> yönetilen TÜM
/// ekipler.
final teamStatsProvider = FutureProvider.autoDispose
    .family<List<TeamStatsShow>, String?>((final ref, final teamId) =>
        ref.watch(teamRepositoryProvider).getTeamStats(teamId: teamId));

/// Bildirim gönderme eylemi — istek/yükleniyor/sonuç durumunu taşır.
/// Klasik `Notifier` (codegen yok, bkz. `team_mutation_provider.dart`
/// örneği).
final sendNotificationProvider =
    NotifierProvider<SendNotificationNotifier, AsyncValue<NotifySendResult?>>(
        SendNotificationNotifier.new);

class SendNotificationNotifier extends Notifier<AsyncValue<NotifySendResult?>> {
  @override
  AsyncValue<NotifySendResult?> build() => const AsyncData(null);

  Future<NotifySendResult> send({
    required final String eventId,
    final String? template,
    final Map<String, int>? params,
    final String? title,
    final String? body,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(teamRepositoryProvider).sendNotification(
            eventId: eventId,
            requestId: _generateRequestId(),
            template: template,
            params: params,
            title: title,
            body: body,
          );
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}

final _requestIdRandom = Random.secure();

/// `teamSendNotification` için 8-64 karakter, `[A-Za-z0-9_-]` istek
/// kimliği — aynı isteğin yinelenmesini engeller (bkz. `functions/src/
/// team.js` > teamSendNotification `requestId` denetimi).
String _generateRequestId() {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final buf = StringBuffer('tm_');
  for (var i = 0; i < 24; i++) {
    buf.write(chars[_requestIdRandom.nextInt(chars.length)]);
  }
  return buf.toString();
}
