import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/events/domain/entities/event.dart';
import 'package:ticketapp/features/players/domain/entities/player.dart';
import 'package:ticketapp/features/search/presentation/providers/search_query_provider.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/features/shows/domain/next_session.dart';
import 'package:ticketapp/features/stages/domain/entities/stage.dart';
import 'package:ticketapp/features/teams/domain/entities/team.dart';

Event _event(final String id, final String date, final String price) => Event(
      id: id,
      stageId: 'stage',
      showId: 'show',
      date: date,
      price: price,
      seats: const {},
    );

Show _show({
  required final String id,
  required final String name,
  final String category = '',
  final String type = '',
  final String description = '',
}) =>
    Show(
      id: id,
      createdAt: '2026-01-01T00:00:00.000',
      updatedAt: '2026-01-01T00:00:00.000',
      name: name,
      description: description,
      imageUrl: '',
      duration: '',
      category: category,
      type: type,
      ageLimit: '',
      eventRule: '',
      teamId: '',
      eventsId: const [],
      nowPlayersId: const [],
      oldPlayersId: const [],
      photosShowId: const [],
    );

Player _player({
  required final String id,
  required final String first,
  required final String last,
  final String bio = '',
  final String quote = '',
}) =>
    Player(
      id: id,
      createdAt: '',
      updatedAt: '',
      firstName: first,
      lastName: last,
      imageUrl: '',
      bio: bio,
      achievements: const [],
      collaborations: const [],
      quote: quote,
      nowShowsId: const [],
      oldShowsId: const [],
    );

Stage _stage({
  required final String id,
  required final String name,
  final String address = '',
  final String description = '',
}) =>
    Stage(
      id: id,
      name: name,
      imageUrl: '',
      capacity: '',
      description: description,
      communication: '',
      address: address,
      locationLat: 0,
      locationLng: 0,
      createdAt: '',
      updatedAt: '',
      showsId: const [],
    );

Team _team({
  required final String id,
  required final String name,
  final String description = '',
}) =>
    Team(
      id: id,
      createdAt: '',
      updatedAt: '',
      name: name,
      description: description,
      imageUrl: '',
      photosId: const [],
      showsId: const [],
    );

void main() {
  final DateTime now = DateTime(2026, 10, 18, 12);

  group('nextSessionHint', () {
    test('geçmiş ve okunamayan seansları atlar, en yakın geleceği seçer', () {
      final NextSessionHint? hint = nextSessionHint([
        _event('past', '10.10.2026,20:00', '100'),
        _event('far', '01.12.2026,21:00', '250'),
        _event('bad', 'yok', '80'),
        _event('near', '20.10.2026,19:30', '150'),
      ], now: now);

      expect(hint, isNotNull);
      expect(hint!.when, DateTime(2026, 10, 20, 19, 30));
      expect(hint.price, 150);
    });

    test('sıfır ve virgüllü fiyatı fiyat olarak göstermez ya da çevirir', () {
      final NextSessionHint? zero = nextSessionHint([
        _event('a', '20.10.2026,19:30', '0'),
      ], now: now);
      expect(zero!.price, isNull);

      final NextSessionHint? comma = nextSessionHint([
        _event('b', '20.10.2026,19:30', '149,50'),
      ], now: now);
      expect(comma!.price, 149.5);
    });

    test('gelecek seans yoksa null döner', () {
      expect(
        nextSessionHint([_event('past', '01.01.2026,20:00', '100')], now: now),
        isNull,
      );
      expect(nextSessionHint(const [], now: now), isNull);
      expect(nextSessionHint(null, now: now), isNull);
    });
  });

  group('displayEventRule', () {
    test('yer tutucu kural metnini gizler', () {
      expect(displayEventRule(''), '');
      expect(displayEventRule('  yok '), '');
      expect(displayEventRule('-'), '');
      expect(displayEventRule('—'), '');
      expect(displayEventRule('None'), '');
      expect(displayEventRule('null'), '');
      expect(displayEventRule('18 yaş sınırı'), '18 yaş sınırı');
    });
  });

  group('arama filtreleri', () {
    test('boş sorgu listeyi olduğu gibi döner', () {
      final shows = [_show(id: '1', name: 'Hamlet')];
      expect(filterShowsForQuery(shows, ''), shows);
    });

    test('tek karakter yalnızca ada bakar', () {
      final shows = [
        _show(id: '1', name: 'Hamlet', category: 'dram'),
        _show(id: '2', name: 'Dede', category: 'komedi'),
      ];
      expect(
        filterShowsForQuery(shows, 'd').map((final s) => s.id),
        ['2'],
      );
    });

    test('ad eşleşmesi tür eşleşmesinin önünde kalır', () {
      final shows = [
        _show(id: 'komedi-tur', name: 'Gece', category: 'komedi'),
        _show(id: 'komedi-ad', name: 'Komedi Saati'),
      ];
      expect(
        filterShowsForQuery(shows, 'komedi').map((final s) => s.id),
        ['komedi-ad', 'komedi-tur'],
      );
    });

    test('oyuncu biyografisi ve repliği iki karakterden itibaren aranır', () {
      final players = [
        _player(id: 'a', first: 'Ayşe', last: 'Yılmaz', bio: 'kadıköy doğumlu'),
        _player(id: 'b', first: 'Can', last: 'Demir', quote: 'perde hiç inmez'),
      ];
      expect(
        filterPlayersForQuery(players, 'kadıköy').map((final p) => p.id),
        ['a'],
      );
      expect(
        filterPlayersForQuery(players, 'perde').map((final p) => p.id),
        ['b'],
      );
      expect(filterPlayersForQuery(players, 'k'), isEmpty);
    });

    test('mekân adresi ve ekip açıklaması aranır', () {
      final stages = [
        _stage(id: 's', name: 'Sahne', address: 'Kadıköy Moda'),
      ];
      final teams = [
        _team(id: 't', name: 'Topluluk', description: 'genç oyuncular'),
      ];
      expect(
        filterStagesForQuery(stages, 'moda').map((final s) => s.id),
        ['s'],
      );
      expect(
        filterTeamsForQuery(teams, 'genç').map((final t) => t.id),
        ['t'],
      );
    });
  });
}
