import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/team.dart';
import '../../repository/team_repository.dart';

abstract class GetTeamByIdUseCase {
  Future<Either<Failure, List<Team>>> call(final List<String> teamsIds);
}

class GetTeamByIdUseCaseImpl implements GetTeamByIdUseCase {
  final TeamRepository repository;

  GetTeamByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Team>>> call(final List<String> teamsIds) async {
    final result = await repository.getTeamsByIds(teamsIds);

    return result.fold(
      (final failure) => Left(failure),
      // Hata durumunda olduğu gibi döndürülür.
      (final teamsModels) {
        // Eğer başarıyla sonuç aldıysak, her TeamModel'i Team entity'ye dönüştürüp yeni bir liste oluşturuyoruz.
        final teams = teamsModels
                ?.map((final teamModel) => teamModel?.toEntity())
                .whereType<Team>()
                .toList() ??
            [];
        return Right(teams); // Success durumunda yeni Team listesi döndürülür.
      },
    );
  }
}
