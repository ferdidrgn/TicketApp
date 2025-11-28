import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_data_guard.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/about_cart.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/contact_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/home_asset_video_provider.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/metafor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/shows_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/team_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/theater_section_divider.dart';
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
    // Sayfa ilk oluştuğunda videoyu hazırlamaya başla
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

    // En tepe kontrolü
    if (scrollPosition < 150) {
      if (widget.activeSection!.value != 'home') {
        widget.activeSection!.value = 'home';
      }
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

    if (currentSection != null &&
        currentSection != widget.activeSection?.value) {
      widget.activeSection?.value = currentSection!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Veri Durumunu İzle
    final videoState = ref.watch(homeAssetsProvider);
    final isVideoReady = videoState.isVideoReady;

    // 2. ✅ VİDEO OYNATMA GARANTİSİ (Geri Dönüş Fix)
    // Eğer video yüklüyse ama durmuşsa (başka sayfadan geri gelindiğinde), tekrar oynat.
    if (isVideoReady && videoState.videoController != null) {
      if (!videoState.videoController!.value.isPlaying) {
        videoState.videoController!.play();
      }
    }

    // 3. ✅ ANİMASYON TETİKLEYİCİSİ
    // Video hazır olduğunda, Splash ekranının kaybolma süresi (yaklaşık 800-1000ms)
    // kadar bekle ve sonra içerik animasyonlarını (yazıların kayması vb.) başlat.
    if (isVideoReady && !_internalAnimationTrigger) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() => _internalAnimationTrigger = true);
        }
      });
    }

    // 4. DataSplashGuard Entegrasyonu
    return SplashDataGuard(
      isLoading: !isVideoReady, // Video hazır değilse Splash göster
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
                    // Hero Section (Video)
                    Container(
                      key: _homeKey,
                      child: HeroVideoSection(
                        // Splash bittikten sonra true olan trigger'ı kullanıyoruz
                        startAnimations: _internalAnimationTrigger,
                      ),
                    ),

                    // Shows
                    Container(
                      key: widget.showsKey,
                      child: const ShowsSection(),
                    ),

                    const TheaterSectionDivider(
                      style: DividerStyle.spotlight,
                      height: 150,
                    ),

                    // Artistic / Metafor
                    Container(
                      key: widget.artisticKey,
                      child: MetaforLanding(),
                    ),

                    const TheaterSectionDivider(
                      style: DividerStyle.spotlight,
                      height: 150,
                    ),

                    const GozYapVazYapLanding(),

                    const TheaterSectionDivider(
                      style: DividerStyle.spotlight,
                      height: 150,
                    ),

                    KurtarBeniDoktorLanding(),

                    const TheaterSectionDivider(
                      style: DividerStyle.iconCenter,
                      height: 120,
                    ),

                    // Info Sections
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
