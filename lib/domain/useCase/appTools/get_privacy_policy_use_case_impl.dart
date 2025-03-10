import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/app_tools_repository.dart';

abstract class GetPrivacyPolicyUseCase {
  Future<Either<Failure, String?>> call();
}

class GetPrivacyPolicyUseCaseImpl implements GetPrivacyPolicyUseCase {
  final AppToolsRepository repository;

  GetPrivacyPolicyUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, String?>> call() async {
    return repository.getPrivacyPolicy();
  }
}
