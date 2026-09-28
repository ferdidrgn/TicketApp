import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/team_repository.dart';

abstract class UpdateTeamUseCase {
  Future<Either<Failure, bool>> call(final String teamId,
      final Map<String, dynamic> updatedData, final File? imageFile);
}

class UpdateTeamUseCaseImpl implements UpdateTeamUseCase {
  final TeamRepository repository;

  UpdateTeamUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String teamId,
          final Map<String, dynamic> updatedData, final File? imageFile) async =>
      repository.updateTeam(teamId, updatedData, imageFile);
}
