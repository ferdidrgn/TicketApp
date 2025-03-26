import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/failures.dart';

abstract class LoginRepository {
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, String?>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> verifyPhone(
      final String phoneNumber,
      final Function(String) onVerificationCompleted,
      final Function(String) onCodeSent,
      final Function(String) onAutoRetrievalTimeout);
  Future<Either<Failure, bool>> verifyOtp(final String verificationId, final String otp);
}
