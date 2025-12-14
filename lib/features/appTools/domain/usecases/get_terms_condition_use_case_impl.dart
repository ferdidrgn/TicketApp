import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../repositories/app_tools_repository.dart';

abstract class GetTermsConditionUseCase {
  Future<Either<Failure, String?>> call();
}

class GetTermsConditionUseCaseImpl implements GetTermsConditionUseCase {
  final AppToolsRepository repository;

  GetTermsConditionUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, String?>> call() async {
    return repository.getTermsCondition();
  }
}
