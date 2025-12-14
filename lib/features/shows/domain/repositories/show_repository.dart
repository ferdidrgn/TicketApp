import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/show_model.dart';

abstract class ShowRepository {
  Future<Either<Failure, List<ShowModel?>?>> getSearchShow(final List<String> categories, final String? type);
  Future<Either<Failure, List<ShowModel?>?>> getShows(final bool isLimit);
  Future<Either<Failure,List<ShowModel?>?>> getShowsByIds(final List<String> showsIds);
  Future<Either<Failure, bool>> addShow(final ShowModel show, final Uri? showIdAddOrUpdateImgUrl);
  Future<Either<Failure, bool>> deleteShow(final String? showId);
  Future<Either<Failure, bool>> updateShow(final String showId, final Map<String, dynamic> updatedData);
}
