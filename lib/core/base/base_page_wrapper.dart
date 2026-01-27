import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import 'package:ticketapp/shared/widgets/button/back_button_glassmorphism.dart';
import 'package:ticketapp/shared/widgets/button/fab_scroll_up.dart';
import '../../features/splash/presentation/widgets/splash_data_guard.dart';

class PageLayoutConfig {
  final Color? backgroundColor;
  final Color? ambientColor;
  final bool usePadding;
  final bool extendBody;

  const PageLayoutConfig({
    this.backgroundColor,
    this.ambientColor,
    this.usePadding = false,
    this.extendBody = true,
  });
}

class BasePageWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final bool showBackButton;
  final bool showFab;
  final bool isLoading; // Splash için
  final bool isOverlayLoading; // Sayfa içi küçük loading için
  final String? loadingMessage;
  final PageLayoutConfig layoutConfig;

  const BasePageWrapper({
    super.key,
    required this.child,
    this.showBackButton = true,
    this.showFab = true,
    this.isLoading = false,
    this.isOverlayLoading = false,
    this.loadingMessage,
    this.layoutConfig = const PageLayoutConfig(),
  });

  @override
  ConsumerState<BasePageWrapper> createState() => _BasePageWrapperState();
}

class _BasePageWrapperState extends ConsumerState<BasePageWrapper>
    with GlobalScrollMixin {
  @override
  Widget build(final BuildContext context) => SplashDataGuard(
        isLoading: widget.isLoading,
        loadingMessage: widget.loadingMessage,
        child: PopScope(
          canPop: false, // Sistem geri tuşunu ele geçiriyoruz
          onPopInvokedWithResult: (final didPop, final result) {
            if (didPop) return;
            // Senin akıllı geri dönme mantığın
            NavigationHandler.smartGoBack(context);
          },
          child: GestureDetector(
            // 1. GLOBAL UNFOCUS: Boşluğa dokununca klavyeyi kapatır
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              extendBodyBehindAppBar: widget.layoutConfig.extendBody,
              body: CustomAppBackground(
                backgroundColor: widget.layoutConfig.backgroundColor,
                ambientColor: widget.layoutConfig.ambientColor,
                child: Stack(
                  children: [
                    // 1. Ana İçerik
                    // ScrollController'ı Mixin'den alıp her sayfaya enjekte ediyoruz
                    Padding(
                      padding: widget.layoutConfig.usePadding
                          ? context
                              .pagePadding // Extension'dan gelen responsive padding
                          : EdgeInsets.zero,
                      child: PrimaryScrollController(
                        controller: scrollController,
                        // Mixin'den gelen controller
                        child: widget.child,
                      ),
                    ),

                    // 2. Akıllı Geri Butonu (Sadece gerekliyse)
                    if (widget.showBackButton &&
                        NavigationHandler.canGoBack(context))
                      Positioned(
                        top: context.responsive(mobile: 50, desktop: 30),
                        left: context.responsive(mobile: 16, desktop: 40),
                        child: const GlassmorphismBackButton(),
                      ),

                    // 3. Yukarı Çık Butonu (Mixin'den gelen showFloatingButton notifier ile)
                    if (widget.showFab)
                      ScrollUpButton(
                          scrollController: scrollController,
                          visibleNotifier: showFloatingButton),

                    //PROGRESSIVE (OVERLAY) LOADING: Sayfa içi şeffaf katman
                    if (widget.isOverlayLoading)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFD4AF37)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
