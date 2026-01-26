import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/show.dart';

abstract class ShowRepository {
  Future<Either<Failure, List<Show>>> getSearchShow(
      final String? query, final List<String> categories, final String? type);

  Future<Either<Failure, List<Show>>> getShows(final bool isLimit);

  Future<Either<Failure, List<Show>>> getShowsByIds(final List<String> showIds);

  // Uri yerine File kullanıyoruz, repository'nin File işlemesi daha sağlıklı
  Future<Either<Failure, bool>> addShow(final Show show, final File? imageFile);

  Future<Either<Failure, bool>> deleteShow(final String showId);

  Future<Either<Failure, bool>> updateShow(
      final String showId, final Map<String, dynamic> updatedData);
}
