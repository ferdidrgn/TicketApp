import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/poll_repository.dart';

// NOT: build_runner çalıştırılamadığı için klasik Provider/FutureProvider (@riverpod YOK).
final Provider<PollRepository> pollRepositoryProvider =
    Provider<PollRepository>((final Ref ref) => PollRepository());

final Provider<PlanRepository> planRepositoryProvider =
    Provider<PlanRepository>((final Ref ref) => PlanRepository());

/// Şu an oy kabul eden anket (yoksa null -> kart hiç görünmez).
final FutureProvider<Poll?> activePollProvider =
    FutureProvider<Poll?>((final Ref ref) => ref.watch(pollRepositoryProvider).activePoll());

/// Kullanıcının bu anketteki oyu (seçenek kimliği). Parametre: "pollId|uid".
final myPollVoteProvider = FutureProvider.family<String?, String>((final Ref ref, final String key) {
  final List<String> p = key.split('|');
  if (p.length != 2 || p[1].isEmpty) return Future<String?>.value(null);
  return ref.watch(pollRepositoryProvider).myVote(p[0], p[1]);
});
