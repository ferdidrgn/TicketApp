import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Color? particleColor;
  final bool usePadding;
  final bool extendBody;

  const PageLayoutConfig({
    this.backgroundColor,
    this.ambientColor,
    this.particleColor,
    this.usePadding = false,
    this.extendBody = true,
  });
}

class BasePageWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? shimmerSkeleton;
  final bool showBackButton;
  final bool showFab;
  final bool isLoading;
  final bool isOverlayLoading;
  final String? loadingMessage;
  final PageLayoutConfig layoutConfig;

  const BasePageWrapper({
    super.key,
    required this.child,
    this.shimmerSkeleton, // Opsiyonel shimmer
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
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;


    // 1. SYSTEM UI YÖNETİMİ: Durum çubuğunu (status bar) sayfa stiline uydurur
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent, // Navbar şeffaflığı
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: SplashDataGuard(
        isLoading: widget.isLoading,
        loadingMessage: widget.loadingMessage,
        child: PopScope(
          canPop: false, // Telefonun geri tuşunu biz yöneteceğiz
          onPopInvokedWithResult: (final didPop, final result) {
            if (didPop) return;
            NavigationHandler.smartGoBack(context);
          },
          child: GestureDetector(
            // 2. GLOBAL UNFOCUS: Boşluğa dokununca klavyeyi kapatır
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              extendBodyBehindAppBar: widget.layoutConfig.extendBody,
              body: CustomAppBackground(
                backgroundColor: widget.layoutConfig.backgroundColor,
                ambientColor: widget.layoutConfig.ambientColor,
                particleColor: widget.layoutConfig.particleColor,
                child: SafeArea(
                  // 🛡️ ASLA KALDIRILMAYAN GÜVENLİ ALAN
                  child: Stack(
                    children: [
                      // 3. ANA İÇERİK
                      Padding(
                        padding: widget.layoutConfig.usePadding
                            ? context.pagePadding
                            : EdgeInsets.zero,
                        child: PrimaryScrollController(
                            controller: scrollController, child: widget.child),
                      ),

                      // 4. AKILLI GERİ BUTONU
                      if (widget.showBackButton &&
                          NavigationHandler.canGoBack(context))
                        Positioned(
                          top: 10,
                          left: 10,
                          child: const GlassmorphismBackButton(),
                        ),

                      // 5. YUKARI ÇIK BUTONU
                      if (widget.showFab)
                        ScrollUpButton(
                            scrollController: scrollController,
                            visibleNotifier: showFloatingButton),

                      // 6. PROGRESSIVE (OVERLAY) LOADING
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
        ),
      ),
    );
  }
}
