import 'package:flutter/material.dart';

class LoadingOverlay {
  static void show(BuildContext context, {String message = 'Yükleniyor...'}) {
    showDialog(
        barrierDismissible: false, // Dışarı tıklanarak kapatılmasın
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              content: Row(children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message)
              ]));
        });
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop(); // Dialog'u kapat
  }
}