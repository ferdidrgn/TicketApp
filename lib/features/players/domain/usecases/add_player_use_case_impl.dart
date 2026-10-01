import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

abstract class AddPlayerUseCase {
  Future<Either<Failure, bool>> call(final Player player, final File? imageFile);
}

class AddPlayerUseCaseImpl implements AddPlayerUseCase {
  final PlayerRepository repository;

  AddPlayerUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final Player player, final File? imageFile) async =>
      repository.addPlayer(player, imageFile);
}
