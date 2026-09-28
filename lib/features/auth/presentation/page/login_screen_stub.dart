import 'package:flutter/material.dart';

/// `home_page_stub.dart` ile aynı kalıp — sadece derleyicinin koşullu
/// export mekanizmasının bir dalı olsun diye var, gerçek platformda hiç
/// çalışmaz.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(final BuildContext context) => throw UnsupportedError(
      'Cannot create LoginScreen. Platform-specific code failed to load.');
}
