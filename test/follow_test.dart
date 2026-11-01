import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/core/services/push/notif_prefs.dart';
import 'package:ticketapp/core/services/push/push_payload.dart';
import 'package:ticketapp/features/follow/follow_logic.dart';

void main() {
  test('etiketler: kalp korunur, takip dili', () {
    expect(followLabel(following: false), 'Takip et');
    expect(followLabel(following: true), 'Takibi bırak');
    expect(followStateWord(following: true), 'Takiptesin');
  });

  test('alan eşlemesi: favori alanlarıyla aynı', () {
    expect(FollowKind.player.field, 'favoritePlayers');
    expect(FollowKind.stage.field, 'favoriteStages');
    expect(FollowKind.team.field, 'favoriteTeams');
  });

  test('öneri: yalnız bir kez ve yalnız newShows kapalıysa', () {
    expect(const NotifPrefs().newShows, isFalse);
    expect(shouldOfferNewShows(alreadyOffered: false, prefs: const NotifPrefs()), isTrue);
    expect(shouldOfferNewShows(alreadyOffered: true, prefs: const NotifPrefs()), isFalse);
    expect(shouldOfferNewShows(alreadyOffered: false, prefs: const NotifPrefs(newShows: true)), isFalse);
    expect(shouldOfferNewShows(alreadyOffered: false, prefs: null), isFalse);
  });

  test('takip kümeleri savunmacı çözülür', () {
    final m = followSetsFromUser({'favoritePlayers': ['a', 3, 'b'], 'favoriteTeams': 'x'});
    expect(m[FollowKind.player], {'a', 'b'});
    expect(m[FollowKind.team], isEmpty);
    expect(followSetsFromUser(null)[FollowKind.stage], isEmpty);
  });

  test('yeni oyun bildirimi rotası /show/<slug>-<id> beyaz listede', () {
    expect(PushRoutes.safeRoute('/show/hamlet-abc123'), '/show/hamlet-abc123');
  });
}
