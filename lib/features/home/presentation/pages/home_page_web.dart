import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../widgets/mobile/mobile_home_canvas.dart';
import '../widgets/sahne/home_experience.dart';

/// ANA SAYFA — WEB. Telefon genişliğinde native mobil yüzeyi, diğer
/// genişliklerde aynı "Sahne" ana sayfasını web iskeleti + footer ile çizer.
///
/// `BasePageWrapper` kullanmadığı için kendi `Scaffold`'unu kurar.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    if (context.isMobile) {
      return const MobileHomeCanvas();
    }
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: HomeExperience(
        controller: _scrollController,
        showActions: false,
        footer: const Padding(
          padding: EdgeInsets.only(top: 72),
          child: Footer(),
        ),
      ),
    );
  }
}
