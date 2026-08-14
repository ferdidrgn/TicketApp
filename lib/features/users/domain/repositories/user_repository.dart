import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/favorite_type.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, bool>> saveUser(final User user, final String downloadUrl, {final bool isUpdate = false});
  Future<Either<Failure, User?>> getUserById(final String userId);
  Future<Either<Failure, bool>> deleteUser(final String userId);
  Future<Either<Failure, bool>> setFavorite(final String userId, final String itemId,
      final FavoriteType type, final bool shouldBeFavorite);
}
