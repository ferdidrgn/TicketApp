import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod eklendi
import 'package:ticketapp/data/providers/login/login_provider.dart'; // Login import
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/about_cart.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/contact_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/home_asset_video_provider.dart'; // Provider import
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/metafor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/shows_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/team_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/theater_section_divider.dart';

import '../../../../mobil/pages/splash/dataguard.dart';
import 'widgets/footer.dart';

// StatefulWidget -> ConsumerStatefulWidget'a çeviriyoruz ki ref kullanabilelim
class HomePage extends ConsumerStatefulWidget {
  final bool startAnimations;
  final GlobalKey showsKey;
  final GlobalKey aboutKey;
  final GlobalKey teamKey;
  final GlobalKey artisticKey;
  final GlobalKey contactKey;
  final ValueNotifier<String>? activeSection;
  final ScrollController scrollController;

  const HomePage({
    super.key,
    required this.showsKey,
    required this.aboutKey,
    required this.teamKey,
    required this.artisticKey,
    required this.contactKey,
    this.activeSection,
    required this.scrollController,
    this.startAnimations = false,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey _homeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);

    // Sayfa açıldığında verileri başlatalım (eğer başlatılmadıysa)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeAssetsProvider.notifier).initializeVideo();
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.activeSection == null) return;
    if (!widget.scrollController.hasClients) return;

    final scrollPosition = widget.scrollController.position.pixels;

    if (scrollPosition < 150) {
      if (widget.activeSection!.value != 'home')
        widget.activeSection!.value = 'home';
      return;
    }

    final sections = {
      'shows': widget.showsKey,
      'artistic': widget.artisticKey,
      'about': widget.aboutKey,
      'team': widget.teamKey,
      'contact': widget.contactKey,
    };

    String? currentSection;
    double minDistance = double.infinity;

    sections.forEach((key, globalKey) {
      final context = globalKey.currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject()! as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        final distance = (position.dy - 100).abs();

        if (distance < minDistance) {
          minDistance = distance;
          currentSection = key;
        }
      }
    });

    if (currentSection != null && currentSection != widget.activeSection?.value)
      widget.activeSection?.value = currentSection!;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Kritik verileri izle
    final videoState = ref.watch(homeAssetsProvider);
    final loginState =
        ref.watch(loginProvider); // İsteğe bağlı, auth beklemek için

    // 2. Yüklenme durumu: Video hazır değilse VEYA Login yükleniyorsa
    // Not: 'fromSplash' parametresi router'dan geliyorsa animasyonu zaten yapmışızdır,
    // ama deep link ile gelindiyse (fromSplash false veya null) bu kontrol çalışır.

    // Basit bir kural: Video hazır değilse Loading'dir.
    final bool isLoading = !videoState.isVideoReady;

    // 3. DataSplashGuard ile tüm sayfayı sarmala
    return DataSplashGuard(
      isLoading: isLoading,
      loadingMessage: 'Oyunlar yükleniyor...',
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            final newOffset =
                widget.scrollController.offset + pointerSignal.scrollDelta.dy;
            widget.scrollController.jumpTo(newOffset.clamp(
              widget.scrollController.position.minScrollExtent,
              widget.scrollController.position.maxScrollExtent,
            ));
          }
        },
        child: Stack(
          children: [
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
                scrollbars: false,
              ),
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                        key: _homeKey,
                        child: HeroVideoSection(
                          startAnimations: widget.startAnimations,
                        )),
                    Container(
                        key: widget.showsKey, child: const ShowsSection()),
                    const TheaterSectionDivider(
                        style: DividerStyle.spotlight, height: 150),
                    Container(key: widget.artisticKey, child: MetaforLanding()),
                    const TheaterSectionDivider(
                        style: DividerStyle.spotlight, height: 150),
                    const GozYapVazYapLanding(),
                    const TheaterSectionDivider(
                        style: DividerStyle.spotlight, height: 150),
                    KurtarBeniDoktorLanding(),
                    const TheaterSectionDivider(
                        style: DividerStyle.iconCenter, height: 120),
                    Container(key: widget.aboutKey, child: AboutCard()),
                    Container(key: widget.teamKey, child: const TeamCard()),
                    Container(
                        key: widget.contactKey, child: const ContactCard()),
                    const ArtFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
