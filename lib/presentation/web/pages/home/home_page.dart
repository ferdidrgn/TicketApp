import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_data_guard.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/about_cart.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/contact_card.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/home_asset_video_provider.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/metafor_landing.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/shows_section.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/team_card.dart';
import 'package:ticketapp/presentation/web/pages/home/widgets/theater_section_divider.dart';
import 'widgets/footer.dart';

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

  // Splash sonrası animasyonları başlatmak için yerel tetikleyici
  bool _internalAnimationTrigger = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);

    // ✅ Video Yükleme Başlatıcı
    WidgetsBinding.instance.addPostFrameCallback((final _) {
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

    // En tepe kontrolü
    if (scrollPosition < 150) {
      if (widget.activeSection!.value != 'home')
        widget.activeSection!.value = 'home';
      return;
    }

    // Scroll pozisyonuna göre aktif bölümü belirle
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
        // Sliver yapısında da global pozisyon hesabı aynı mantıkla çalışır
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
    // 1. Veri Durumunu İzle
    final videoState = ref.watch(homeAssetsProvider);
    final isVideoReady = videoState.isVideoReady;

    // 2. Video Oynatma Garantisi
    if (isVideoReady && videoState.videoController != null) if (!videoState
        .videoController!.value.isPlaying) videoState.videoController!.play();

    // 3. Animasyon Tetikleyicisi
    if (isVideoReady && !_internalAnimationTrigger)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _internalAnimationTrigger = true);
      });

    return SplashDataGuard(
      isLoading: !isVideoReady,
      loadingMessage: 'Oyunlar yükleniyor...',
      child: Listener(
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
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
            scrollbars: false,
          ),
          // 🔥 PERFORMANS İÇİN DÖNÜŞTÜRÜLDÜ: CustomScrollView
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: const BouncingScrollPhysics(),
            // 🔥 CRITICAL: Ekrana girmeden 1500px öncesini render et.
            // Bu sayede kullanıcı scroll yaparken beyaz ekran görmez ama
            // tüm sayfa da baştan yüklenmez.
            cacheExtent: 1500,
            slivers: [
              // 1. Hero Section (Video)
              SliverToBoxAdapter(
                key: _homeKey,
                // Video zaten ağır olduğu için RepaintBoundary'ye gerek yok, kendi içinde yönetiyor.
                child: HeroVideoSection(
                    startAnimations: _internalAnimationTrigger),
              ),

              // 2. Shows Section
              SliverToBoxAdapter(
                  key: widget.showsKey, child: const ShowsSection()),

              const SliverToBoxAdapter(
                  child: TheaterSectionDivider(
                      style: DividerStyle.spotlight, height: 150)),

              // 3. Artistic / Metafor Landing
              SliverToBoxAdapter(
                  key: widget.artisticKey,
                  // 🔥 RepaintBoundary: Bu bölümün animasyonu diğerlerini etkilemesin.
                  child: const RepaintBoundary(child: MetaforLanding())),

              const SliverToBoxAdapter(
                  child: TheaterSectionDivider(
                      style: DividerStyle.spotlight, height: 150)),

              // 4. Göz Kap Vaz Yap Landing
              const SliverToBoxAdapter(
                  child: RepaintBoundary(child: GozYapVazYapLanding())),

              const SliverToBoxAdapter(
                  child: TheaterSectionDivider(
                      style: DividerStyle.spotlight, height: 150)),

              // 5. Kurtar Beni Doktor Landing
              SliverToBoxAdapter(
                  child: RepaintBoundary(child: KurtarBeniDoktorLanding())),

              const SliverToBoxAdapter(
                  child: TheaterSectionDivider(
                      style: DividerStyle.iconCenter, height: 120)),

              // 6. Info Sections (About, Team, Contact)
              SliverToBoxAdapter(key: widget.aboutKey, child: AboutCard()),

              SliverToBoxAdapter(key: widget.teamKey, child: const TeamCard()),

              SliverToBoxAdapter(
                  key: widget.contactKey, child: const ContactCard()),

              // 7. Footer
              const SliverToBoxAdapter(child: ArtFooter()),
            ],
          ),
        ),
      ),
    );
  }
}
