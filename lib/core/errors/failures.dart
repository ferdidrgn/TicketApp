import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

extension FutureEitherX<T> on Future<Either<Failure, T>> {
  /// Future içindeki Either sonucunu bekler ve çözer.
  Future<T> getOrThrow() async {
    final result = await this;
    return result.getOrThrow();
  }
}

extension EitherX<T> on Either<Failure, T> {
  /// Doğrudan Either nesnesini çözer.
  T getOrThrow() => fold(
        (final failure) => throw Exception(failure.message),
        (final success) => success,
      );
}
