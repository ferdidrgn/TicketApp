import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../presentation/pages/login/verify_otp_page.dart';

class PhoneAuthController {
  static final _auth = FirebaseAuth.instance;

  static Future<void> sendOtp(BuildContext context, String phoneNumber,
      {int? forceResendingToken}) async {
    try {
      _showLoadingDialog(context);
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        codeSent: (verificationId, resendingToken) {
          _hideLoadingDialog(context);

          if (forceResendingToken == null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerifyOtpPage(
                    phone: phoneNumber,
                    verificationId: verificationId,
                    forceResendingToken: resendingToken,
                  ),
                ));
          }
        },
        verificationCompleted: (phoneAuthCredential) async {
          final smsCode = phoneAuthCredential.smsCode;
          print("Verification completed: $smsCode");
        },
        verificationFailed: (error) {
          _handleError(context, error.message);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _hideLoadingDialog(context);
        },
      );
    } catch (e) {
      _handleError(context, e.toString());
    }
    finally {
      _hideLoadingDialog(context);
    }
  }

  static Future<void> logout(BuildContext context) async {
    try {
      _showLoadingDialog(context);
      await _auth.signOut();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _handleError(context, e.toString());
    }
    finally {
      _hideLoadingDialog(context);
    }
  }

  static Future<void> verifyOtp(
      {required BuildContext context,
      required String otp,
      required String verificationId}) async {
    try {
      _showLoadingDialog(context);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: otp);
      await _auth.signInWithCredential(credential);
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _handleError(context, e.toString());
    }
    finally {
      _hideLoadingDialog(context);
    }
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
        barrierDismissible: false, // Dışarı tıklanarak kapatılmasın
        context: context,
        builder: (BuildContext context) {
          return const AlertDialog(
              content: Row(children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Loading...")
          ]));
        });
  }

  static void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  static void _handleError(BuildContext context, String? message) {
    _hideLoadingDialog(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message.toString())));
  }
}
