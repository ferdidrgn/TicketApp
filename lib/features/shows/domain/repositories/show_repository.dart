import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/show.dart';

abstract class ShowRepository {
  Future<Either<Failure, List<Show>>> getSearchShow(final List<String> categories, final String? type);
  Future<Either<Failure, List<Show>>> getShows(final bool isLimit);
  Future<Either<Failure, List<Show>>> getShowsByIds(final List<String> showIds);
  Future<Either<Failure, bool>> addShow(final Show show, final Uri? showIdAddOrUpdateImgUrl);
  Future<Either<Failure, bool>> deleteShow(final String showId);
  Future<Either<Failure, bool>> updateShow(final String showId, final Map<String, dynamic> updatedData);
}
