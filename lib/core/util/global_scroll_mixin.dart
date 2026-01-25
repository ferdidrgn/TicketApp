import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

mixin GlobalScrollMixin<T extends StatefulWidget> on State<T> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_globalScrollListener);
  }

  void _globalScrollListener() {
    // 1. Kullanıcı kaydırırken klavyeyi kapatma
    if (scrollController.position.userScrollDirection != ScrollDirection.idle)
      FocusManager.instance.primaryFocus?.unfocus();

    // 2. Sayfalama (Pagination) Tetikleyici
    // Eğer sayfada özel bir pagination logic'i varsa onu çağırır
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent * 0.9) onLoadMore();
  }

  /// Alt sınıflar bu metodu override ederek yeni veri çekebilir
  void onLoadMore() {}

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
