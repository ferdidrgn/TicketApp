import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

abstract class GetPlayerSearchUseCase {
  Future<Either<Failure, List<Player>>> call(final String? query);
}

class GetPlayerSearchUseCaseImpl implements GetPlayerSearchUseCase {
  final PlayerRepository repository;

  GetPlayerSearchUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Player>>> call(final String? query) async {
    // Query null ise veya boşsa doğrudan boş liste dönerek hatayı engelle
    if (query == null || query.trim().isEmpty) return const Right([]);

    return repository.searchPlayers(query);
  }
}
