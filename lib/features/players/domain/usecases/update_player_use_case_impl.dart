import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/player_repository.dart';

abstract class UpdatePlayerUseCase {
  Future<Either<Failure, bool>> call(final String playerId,
      final Map<String, dynamic> updatedData, final File? imageFile);
}

class UpdatePlayerUseCaseImpl implements UpdatePlayerUseCase {
  final PlayerRepository repository;

  UpdatePlayerUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String playerId,
          final Map<String, dynamic> updatedData, final File? imageFile) async =>
      repository.updatePlayer(playerId, updatedData, imageFile);
}
