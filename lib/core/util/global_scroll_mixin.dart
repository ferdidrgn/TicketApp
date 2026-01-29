import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

mixin GlobalScrollMixin<T extends StatefulWidget> on State<T> {
  late ScrollController scrollController;

  // UI durumlarını kontrol etmek için ValueNotifier (Rebuild maliyetini düşürür)
  final ValueNotifier<bool> showFloatingButton = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAtBottom = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_enhancedScrollListener);
  }

  void _enhancedScrollListener() {
    // Eğer controller bir listeye bağlı değilse (Shimmer aşaması) işlem yapma
    if (!scrollController.hasClients) return;

    final double offset = scrollController.offset;
    final double maxScroll = scrollController.position.maxScrollExtent;
    final ScrollDirection direction =
        scrollController.position.userScrollDirection;

    // 1. Performanslı Klavye Kapatma (Sadece aşağı kaydırırken)
    if (direction == ScrollDirection.reverse) {
      if (FocusManager.instance.primaryFocus?.hasFocus ?? false)
        FocusManager.instance.primaryFocus?.unfocus();
    }

    // 2. Yukarı Çık Butonu Kontrolü (200px geçince göster)
    if (offset > 200 && !showFloatingButton.value)
      showFloatingButton.value = true;
    else if (offset <= 200 && showFloatingButton.value)
      showFloatingButton.value = false;

    // 3. Verimli Pagination & Footer Tespiti
    // %90 yerine "Kalan Mesafe" (Threshold) mantığı daha stabildir
    const double threshold = 200.0;
    final bool nearBottom = offset >= (maxScroll - threshold);

    if (nearBottom && !isAtBottom.value) {
      isAtBottom.value = true;
      onLoadMore();
    } else if (!nearBottom && isAtBottom.value) isAtBottom.value = false;
  }

  /// Sayfa sonuna gelindiğinde tetiklenir
  void onLoadMore() {}

  /// En başa yumuşak geçişle kaydır
  void scrollToTop() {
    if (scrollController.hasClients)
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
  }

  @override
  void dispose() {
    scrollController.removeListener(_enhancedScrollListener);
    scrollController.dispose();
    showFloatingButton.dispose();
    isAtBottom.dispose();
    super.dispose();
  }
}
