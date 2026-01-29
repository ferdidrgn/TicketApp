import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
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
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final EdgeInsets? customPadding;

  const PageBackgroundLayoutConfig({
    this.backgroundColor,
    this.ambientColor,
    this.particleColor,
    this.usePadding = false,
    this.extendBody = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.customPadding,
  });
}

/// 🎨 BASE PAGE WRAPPER
///
/// Tüm sayfalar için temel wrapper
/// - Background (ambient + particles)
/// - Back button
/// - FAB (opsiyonel scroll controller ile)
/// - Loading states
/// - System UI overlay

class BasePageWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? shimmerSkeleton;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool showBackButton;
  final bool showFab;
  final bool isLoading;
  final bool isOverlayLoading;
  final PageBackgroundLayoutConfig layoutConfig;
  final VoidCallback? onRefresh;
  final bool resizeToAvoidBottomInset;
  final ScrollController?
      customScrollController; // ✅ Opsiyonel scroll controller

  const BasePageWrapper({
    super.key,
    required this.child,
    this.shimmerSkeleton,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.showBackButton = true,
    this.showFab = false,
    this.isLoading = false,
    this.isOverlayLoading = false,
    this.layoutConfig = const PageBackgroundLayoutConfig(),
    this.onRefresh,
    this.resizeToAvoidBottomInset = true,
    this.customScrollController,
  });

  @override
  ConsumerState<BasePageWrapper> createState() => _BasePageWrapperState();
}

class _BasePageWrapperState extends ConsumerState<BasePageWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ValueNotifier<bool> _showFabNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    if (!widget.isLoading) _fadeController.forward();

    // FAB visibility listener
    if (widget.customScrollController != null)
      widget.customScrollController!.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(final BasePageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) _fadeController.forward();

    // Update scroll listener
    if (oldWidget.customScrollController != widget.customScrollController) {
      oldWidget.customScrollController?.removeListener(_onScroll);
      widget.customScrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _showFabNotifier.dispose();
    widget.customScrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    // 1. Güvenlik kilidi: Controller yoksa, bağlı değilse veya sayfa yükleniyorsa çalışma
    if (widget.customScrollController == null ||
        !widget.customScrollController!.hasClients ||
        widget.isLoading) return;

    try {
      // Scroll değerini alırken hata oluşma ihtimaline karşı try-catch
      final double offset = widget.customScrollController!.offset;
      final bool showFab = offset > 200;

      if (_showFabNotifier.value != showFab) _showFabNotifier.value = showFab;
    } catch (e) {
      debugPrint("Scroll listener error: $e");
    }
  }

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;

    // LOADING + SHIMMER
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

    // MAIN CONTENT
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
            resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
            floatingActionButton: widget.floatingActionButton,
            floatingActionButtonLocation: widget.floatingActionButtonLocation,
            bottomNavigationBar: widget.bottomNavigationBar,
            bottomSheet: widget.bottomSheet,
            body: CustomAppBackground(
              backgroundColor: widget.layoutConfig.backgroundColor,
              ambientColor: widget.layoutConfig.ambientColor,
              particleColor: widget.layoutConfig.particleColor,
              child: SafeArea(
                top: widget.layoutConfig.safeAreaTop,
                bottom: widget.layoutConfig.safeAreaBottom,
                child: Stack(
                  children: [
                    // CONTENT
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: widget.onRefresh != null
                          ? RefreshIndicator(
                              onRefresh: () async => widget.onRefresh?.call(),
                              color: context.colors.primary,
                              child: _buildContent())
                          : _buildContent(),
                    ),

                    // BACK BUTTON
                    if (widget.showBackButton &&
                        NavigationHandler.canGoBack(context))
                      Positioned(
                        top: 10,
                        left: 10,
                        child: const GlassmorphismBackButton(),
                      ),

                    // SCROLL UP FAB
                    if (widget.showFab &&
                        widget.customScrollController != null &&
                        !widget.isLoading)
                      ValueListenableBuilder<bool>(
                        valueListenable: _showFabNotifier,
                        builder: (final context, final show, final child) {
                          if (!show) return const SizedBox.shrink();
                          return ScrollUpButton(
                            scrollController: widget.customScrollController!,
                            visibleNotifier: _showFabNotifier,
                          );
                        },
                      ),

                    // OVERLAY LOADING
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

  Widget _buildContent() => Padding(
      padding: widget.layoutConfig.customPadding ??
          (widget.layoutConfig.usePadding
              ? context.pagePadding
              : EdgeInsets.zero),
      child: widget.child);

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
        child: Center(
          child: CircularProgressIndicator.adaptive(
              valueColor:
                  AlwaysStoppedAnimation<Color>(context.colors.primary)),
        ),
      );
}
