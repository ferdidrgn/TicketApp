import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/model/show_model.dart';

abstract class ShowRepository {
  Future<Either<Failure, List<ShowModel?>>> getSearchShow(final List<String?> categories, final String? type);
  Future<Either<Failure, List<ShowModel?>>> getShows(final isLimit);
  Future<Either<Failure, ShowModel?>> getShowById(final String showId);
  Future<Either<Failure, void>> addShow(final ShowModel show, final Uri? showIdAddOrUpdateImgUrl);
  Future<Either<Failure, void>> deleteShow(final String? showId);
  Future<Either<Failure, void>> updateShow(final String showId, final Map<String, dynamic> updatedData);
}
