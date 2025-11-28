import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/about_cart.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/contact_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/metafor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/shows_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/team_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/theater_section_divider.dart';
import 'widgets/footer.dart';

class HomePage extends StatefulWidget {
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _homeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.activeSection == null) return;
    // ScrollController bağlı değilse hata vermemesi için kontrol
    if (!widget.scrollController.hasClients) return;

    final scrollPosition = widget.scrollController.position.pixels;

    // ✅ EN TEPE KONTROLÜ
    if (scrollPosition < 150) {
      if (widget.activeSection!.value != 'home')
        widget.activeSection!.value = 'home';
      return;
    }

    // Diğer bölümlerin kontrolü
    final sections = {
      'shows': widget.showsKey,
      'artistic': widget.artisticKey,
      'about': widget.aboutKey,
      'team': widget.teamKey,
      'contact': widget.contactKey,
    };

    String? currentSection;
    double minDistance = double.infinity;

    sections.forEach((final key, final globalKey) {
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
  Widget build(final BuildContext context) {
    return Listener(
      // Sadece normal mouse wheel scroll desteği kaldı
      onPointerSignal: (final pointerSignal) {
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
          // Ana içerik
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
                  // ✅ DEĞİŞTİ: Hero Section - startAnimations parametresini geç
                  Container(
                      key: _homeKey,
                      child: HeroVideoSection(
                        startAnimations: widget
                            .startAnimations, // ← BURAYA EKLEYİN
                      )
                  ),

                  // Shows Section
                  Container(key: widget.showsKey, child: const ShowsSection()),

                  const TheaterSectionDivider(
                      style: DividerStyle.spotlight, height: 150),

                  // Metafor Landing
                  Container(key: widget.artisticKey, child: MetaforLanding()),

                  const TheaterSectionDivider(
                      style: DividerStyle.spotlight, height: 150),

                  // Göz Kap Vaz Yap Landing
                  const GozYapVazYapLanding(),

                  const TheaterSectionDivider(
                      style: DividerStyle.spotlight, height: 150),

                  // Kurtar Beni Doktor Landing
                  KurtarBeniDoktorLanding(),

                  // 4. GEÇİŞ: OYUNLAR BİTTİ -> HAKKIMIZDA
                  const TheaterSectionDivider(
                      style: DividerStyle.iconCenter, height: 120),

                  // About Section
                  Container(key: widget.aboutKey, child: AboutCard()),
                  // Team Section
                  Container(key: widget.teamKey, child: const TeamCard()),
                  // Contact Section
                  Container(key: widget.contactKey, child: const ContactCard()),

                  const ArtFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
