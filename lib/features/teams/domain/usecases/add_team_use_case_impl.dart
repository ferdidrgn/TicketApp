import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

abstract class AddTeamUseCase {
  Future<Either<Failure, bool>> call(final Team team, final File? imageFile);
}

class AddTeamUseCaseImpl implements AddTeamUseCase {
  final TeamRepository repository;

  AddTeamUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final Team team, final File? imageFile) async =>
      repository.addTeam(team, imageFile);
}
