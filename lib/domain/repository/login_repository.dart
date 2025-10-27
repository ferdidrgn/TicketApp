import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/errors/failures.dart';

abstract class LoginRepository {
  Future<Either<Failure, User?>> getCurrentUser();

  Future<Either<Failure, GoogleSignInAccount?>> signInWithGoogle();

  Future<Either<Failure, bool>> signOut();

  Future<Either<Failure, bool>> verifyPhone(
    final String phoneNumber, {
    required final void Function(String) onVerificationCompleted,
    required final void Function(String) onCodeSent,
    required final void Function(String) onAutoRetrievalTimeout,
  });

  Future<Either<Failure, bool>> verifyOtp(
      final String verificationId, final String otp);
}
