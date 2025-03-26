import 'package:dartz/dartz.dart';
import 'package:ticketapp/domain/repository/seat_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class GetSeatsByStageUseCase {
  Future<Either<Failure, Map<String, List<String>>?>> call(
      final String stageId);
}

class GetSeatsByStageUseCaseImpl implements GetSeatsByStageUseCase {
  final SeatRepository seatRepository;

  GetSeatsByStageUseCaseImpl(this.seatRepository);

  @override
  Future<Either<Failure, Map<String, List<String>>?>> call(
      final String stageId) async {
    final result = await seatRepository.getSeatsByStage(stageId);
    return result.fold(
      (final failure) => Left(failure),
      (final seats) {
        // seats Map<String, List<String?>?>? tipinde olduğundan, her List<String?>? için null kontrolü yapıyoruz
        final cleanedSeats = seats?.map((final key, final value) {
              // Eğer value (List<String?>?) null değilse, null değerleri temizleyip List<String> yapıyoruz
              final cleanedList = value
                      ?.where((final e) => e != null)
                      .map((final e) => e!)
                      .toList() ??
                  [];
              return MapEntry(key, cleanedList);
            }) ??
            {};
        return Right(cleanedSeats);
      },
    );
  }
}
