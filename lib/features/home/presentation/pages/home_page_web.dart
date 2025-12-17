import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/about/presentation/widgets/contact_card_web.dart';
import 'package:ticketapp/features/home/presentation/widgets/web/hero_video_section.dart';
import 'package:ticketapp/features/home/presentation/widgets/web/theater_section_divider.dart';
import 'package:ticketapp/features/shows/presentation/widgets/web/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/features/shows/presentation/widgets/web/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/features/shows/presentation/widgets/web/shows_section_web.dart';
import 'package:ticketapp/features/splash/presentation/widgets/splash_data_guard.dart';
import 'package:ticketapp/features/teams/presentation/pages/team_card_web.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../about/presentation/widgets/about_cart_web.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/web/metafor_landing.dart';
import '../providers/home_asset_video_provider.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      // 1. Video assetlerini başlat
      ref.read(homeAssetsProvider.notifier).initializeVideo();
      ref.read(showProvider.notifier).loadShows(false);
      // ----------------------------------------
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
        // Sliver yapısında global pozisyon
        final position = box.localToGlobal(Offset.zero);
        // Header payı vb. için offset eklenebilir
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
    final videoState = ref.watch(homeAssetsProvider);
    final isVideoReady = videoState.isVideoReady;

    if (isVideoReady &&
        videoState.videoController != null &&
        !videoState.videoController!.value.isPlaying)
      videoState.videoController!.play();

    if (isVideoReady && !_internalAnimationTrigger)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _internalAnimationTrigger = true);
      });

    return SplashDataGuard(
      isLoading: !isVideoReady,
      loadingMessage: 'Oyunlar yükleniyor...',
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          // Mouse ile sürüklemeyi aktif ettik, ama manuel Listener'ı kaldırdık
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
          scrollbars: false,
        ),
        child: CustomScrollView(
          controller: widget.scrollController,
          // Web için Clamping daha stabil hissettirebilir, ama Bouncing de olur
          physics: const BouncingScrollPhysics(),
          // Cache alanını büyüttük ki geri dönünce yeniden çizmesin
          cacheExtent: 3000,
          slivers: [
            // 1. Hero Section (KeepAlive Eklendi)
            // Bu sayede aşağı inip yukarı çıkınca video baştan yüklenmez/yanıp sönmez.
            SliverToBoxAdapter(
              key: _homeKey,
              child: _KeepAliveWrapper(
                child: HeroVideoSection(
                  startAnimations: _internalAnimationTrigger,
                ),
              ),
            ),

            // 2. Shows Section
            SliverToBoxAdapter(
              key: widget.showsKey,
              child: const ShowsSection(),
            ),

            const SliverToBoxAdapter(
              child: TheaterSectionDivider(
                style: DividerStyle.spotlight,
                height: 150,
              ),
            ),

            // 3. Artistic Section
            SliverToBoxAdapter(
              key: widget.artisticKey,
              child: const RepaintBoundary(child: MetaforLanding()),
            ),

            const SliverToBoxAdapter(
              child: TheaterSectionDivider(
                style: DividerStyle.spotlight,
                height: 150,
              ),
            ),

            // 4. Goz Kap Vaz Yap
            const SliverToBoxAdapter(
              child: RepaintBoundary(child: GozYapVazYapLanding()),
            ),

            const SliverToBoxAdapter(
              child: TheaterSectionDivider(
                style: DividerStyle.spotlight,
                height: 150,
              ),
            ),

            // 5. Kurtar Beni Doktor
            SliverToBoxAdapter(
              child: RepaintBoundary(child: KurtarBeniDoktorLanding()),
            ),

            const SliverToBoxAdapter(
              child: TheaterSectionDivider(
                style: DividerStyle.iconCenter,
                height: 120,
              ),
            ),

            // 6. Info Sections
            SliverToBoxAdapter(key: widget.aboutKey, child: AboutCard()),
            SliverToBoxAdapter(key: widget.teamKey, child: const TeamCard()),
            SliverToBoxAdapter(
                key: widget.contactKey, child: const ContactCard()),
            const SliverToBoxAdapter(child: Footer()),
          ],
        ),
      ),
    );
  }
}

// 🔥 ÖNEMLİ: Widget aşağıda veya yukarıda kalsa bile hafızada tutmak için bu wrapper'ı kullanıyoruz.
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(final BuildContext context) {
    super.build(context); // Bunu çağırmak zorunludur
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true; // Sayfa scroll olsa bile bu widget'ı öldürme
}
