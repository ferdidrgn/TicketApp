import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/pages/login/login.dart';
import '../../presentation/pages/login/verify_otp_page.dart';

class PhoneAuthController {
  static final _auth = FirebaseAuth.instance;

  static Future<void> sendOtp(BuildContext context, String phoneNumber, {int? forceResendingToken}) async {
    try {
      _showLoadingDialog(context);
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        codeSent: (verificationId, x) {
          _hideLoadingDialog(context);

          if (forceResendingToken == null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyOtpPage(
                  phone: phoneNumber,
                  verificationId: verificationId,
                  forceResendingToken: x,
                ),
              ),
            );
          }
        },
        verificationCompleted: (phoneAuthCredential) async {
          final smsCode = phoneAuthCredential.smsCode;
          print("Verification completed $smsCode");
        },
        verificationFailed: (error) {
          _hideLoadingDialog(context);
          ScaffoldMessenger.of(context)
            ..hideCurrentMaterialBanner()
            ..showSnackBar(SnackBar(content: Text("${error.message}")));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _hideLoadingDialog(context);
        },
      );
    } on FirebaseAuthException catch (e) {
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentMaterialBanner()
        ..showSnackBar(SnackBar(content: Text("${e.message}")));
    } catch (e) {
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("${e.toString()}")));
    }
  }

  static Future<void> logout(BuildContext context) async {
    try {
      _showLoadingDialog(context);
      await _auth.signOut();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("${e.toString()}")));
    } finally {
      _hideLoadingDialog(context); // Loading dialog'u gizle
    }
  }

  static Future<void> verifyOtp(
      {required BuildContext context, required String otp, required String verificationId}) async {
    try {
      _showLoadingDialog(context);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _hideLoadingDialog(context); // Loading dialog'u gizle
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("${e.toString()}")));
    } finally {
      _hideLoadingDialog(context); // Loading dialog'u gizle
    }
  }

  // Loading dialog'u gösteren fonksiyon
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false, // Dışarı tıklanarak kapatılmasın
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Loading..."),
            ],
          ),
        );
      },
    );
  }

  // Loading dialog'u gizleyen fonksiyon
  static void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop(); // En son açılan dialog'u kapat
  }
}