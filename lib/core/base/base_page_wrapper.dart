import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/util/global_scroll_mixin.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import 'package:ticketapp/shared/widgets/button/back_button_glassmorphism.dart';
import 'package:ticketapp/shared/widgets/button/fab_scroll_up.dart';

class PageBackgroundLayoutConfig {
  final Color? backgroundColor;
  final Color? ambientColor;
  final Color? particleColor;
  final bool usePadding;
  final bool extendBody;

  const PageBackgroundLayoutConfig({
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
  final PreferredSizeWidget? appBar;
  final bool showBackButton;
  final bool showFab;
  final bool isLoading;
  final bool isOverlayLoading;
  final PageBackgroundLayoutConfig layoutConfig;

  const BasePageWrapper({
    super.key,
    required this.child,
    this.shimmerSkeleton,
    this.appBar,
    this.showBackButton = true,
    this.showFab = true,
    this.isLoading = false,
    this.isOverlayLoading = false,
    this.layoutConfig = const PageBackgroundLayoutConfig(),
  });

  @override
  ConsumerState<BasePageWrapper> createState() => _BasePageWrapperState();
}

class _BasePageWrapperState extends ConsumerState<BasePageWrapper>
    with GlobalScrollMixin {
  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;

    if (widget.isLoading && widget.shimmerSkeleton != null)
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: _getSystemUiStyle(isDark),
        child: Scaffold(
          appBar: widget.appBar,
          body: CustomAppBackground(
            backgroundColor: widget.layoutConfig.backgroundColor,
            ambientColor: widget.layoutConfig.ambientColor,
            particleColor: widget.layoutConfig.particleColor,
            child: SafeArea(child: widget.shimmerSkeleton!),
          ),
        ),
      );

    // 2. ANA SAYFA AKIŞI
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _getSystemUiStyle(isDark),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (final didPop, final result) {
          if (didPop) return;
          NavigationHandler.smartGoBack(context);
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: widget.appBar,
            extendBodyBehindAppBar: widget.layoutConfig.extendBody,
            body: CustomAppBackground(
              backgroundColor: widget.layoutConfig.backgroundColor,
              ambientColor: widget.layoutConfig.ambientColor,
              particleColor: widget.layoutConfig.particleColor,
              child: SafeArea(
                child: Stack(
                  children: [
                    // --- İÇERİK ---
                    Padding(
                      padding: widget.layoutConfig.usePadding
                          ? context.pagePadding
                          : EdgeInsets.zero,
                      child: PrimaryScrollController(
                          controller: scrollController, child: widget.child),
                    ),

                    // --- GERİ BUTONU ---
                    if (widget.showBackButton &&
                        NavigationHandler.canGoBack(context))
                      Positioned(
                        top: 10,
                        left: 10,
                        child: const GlassmorphismBackButton(),
                      ),

                    // --- YUKARI ÇIK BUTONU ---
                    if (widget.showFab)
                      ScrollUpButton(
                          scrollController: scrollController,
                          visibleNotifier: showFloatingButton),

                    // --- OVERLAY LOADING ---
                    if (widget.isOverlayLoading) _buildOverlayLoading(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  SystemUiOverlayStyle _getSystemUiStyle(final bool isDark) =>
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      );

  Widget _buildOverlayLoading() => Container(
        color: Colors.black.withOpacity(0.4),
        child: const Center(
            child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)))),
      );
}
