import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/favorite_type.dart';
import '../repositories/user_repository.dart';

abstract class SetFavoriteUseCase {
  Future<Either<Failure, bool>> call(final String userId, final String itemId,
      final FavoriteType type, final bool shouldBeFavorite);
}

class SetFavoriteUseCaseImpl implements SetFavoriteUseCase {
  final UserRepository repository;

  SetFavoriteUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String userId, final String itemId,
          final FavoriteType type, final bool shouldBeFavorite) async =>
      repository.setFavorite(userId, itemId, type, shouldBeFavorite);
}
