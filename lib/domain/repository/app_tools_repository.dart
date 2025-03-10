import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

abstract class AppToolsRepository {
  Future<Either<Failure, String?>> getPrivacyPolicy();
  Future<Either<Failure, String?>> getTermsCondition();
}
