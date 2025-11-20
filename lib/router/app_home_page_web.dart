import 'package:flutter/material.dart';
import '../presentation/web/navigation/widgets/main_scaffold.dart';

/// Web için kullanılacak ana widget'ı döndürür
/// Modern scaffold yapısı ile active section tracking ve smooth scroll
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(final BuildContext context) => const MainScaffold();
}
