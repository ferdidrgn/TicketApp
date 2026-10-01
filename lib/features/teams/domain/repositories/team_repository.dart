import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/team.dart';

abstract class TeamRepository {
  Future<Either<Failure, List<Team>>> getTeams(final bool isLimit);
  Future<Either<Failure, List<Team>>> getTeamsByIds(final List<String> teamIds);

  /// ➕ Admin panelinden yeni bir topluluk (Team) oluşturur.
  Future<Either<Failure, bool>> addTeam(final Team team, final File? imageFile);

  /// 🔄 Admin panelinden bir topluluğu günceller (Phase 2). `imageFile`
  /// verilirse görsel `addTeam` ile AYNI Storage yoluna yeniden yüklenir.
  Future<Either<Failure, bool>> updateTeam(final String teamId,
      final Map<String, dynamic> updatedData, final File? imageFile);

  /// 🗑️ Admin panelinden bir topluluğu siler (Phase 2).
  Future<Either<Failure, bool>> deleteTeam(final String teamId);
}
