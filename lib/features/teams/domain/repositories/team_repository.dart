import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/team.dart';

abstract class TeamRepository {
  Future<Either<Failure, List<Team>>> getTeams(final bool isLimit);
  Future<Either<Failure, List<Team>>> getTeamsByIds(final List<String> teamIds);

  /// ➕ Admin panelinden yeni bir topluluk (Team) oluşturur.
  Future<Either<Failure, bool>> addTeam(final Team team, final File? imageFile);
}
