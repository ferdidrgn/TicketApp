import 'package:flutter/material.dart';
import '../../../core/util/phone_sign_in_service.dart';

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  String phone = "";
  bool enableOtpBtn = false;

  Future<void> getOtp() async {
    PhoneAuthController.sendOtp(context, phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Telefon Numaranızı Giriniz"),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              const Text("Doğrulama Gerekiyor..."),
              const SizedBox(height: 30),
              TextField(
                onChanged: (value) {
                  phone = value;
                  // Telefon numarası girildiğinde butonu aktif et
                  setState(() {
                    enableOtpBtn = value.isNotEmpty;
                  });
                },
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "+90***********",
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: enableOtpBtn ? getOtp : null,
                  child: const Text("Kod Gönder"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}