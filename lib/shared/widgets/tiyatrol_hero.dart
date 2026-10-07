import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Liste kartı → detay kapağı paylaşılmış öğe geçişi.
///
/// Etiketler konum soneki taşır (`show_$id_home` / `show_$id_search`) —
/// `StatefulShellRoute` IndexedStack'te aynı oyun iki sekmede durduğu için
/// ham `show_$id` çift Hero hatası verir. Uçuş etiketi `goToShow` extra'sı
/// ve [TiyatrolHeroFlight] ile detaya iletilir.
abstract final class TiyatrolHeroTags {
  static String show(final String id, [final String from = 'card']) =>
      'show_${id}_$from';

  static String player(final String id, [final String from = 'card']) =>
      'player_${id}_$from';

  static String stage(final String id, [final String from = 'card']) =>
      'stage_${id}_$from';

  static String team(final String id, [final String from = 'card']) =>
      'team_${id}_$from';
}

/// Kart dokunuşunda yazılır; detay rotası extra'sız açılırsa (derin bağ)
/// yedek olarak okunur. Afiş URL'si ilk karede Hero için şart — shimmer
/// beklenirse uçuş kaçar.
abstract final class TiyatrolHeroFlight {
  static String? pendingTag;
  static String? pendingImageUrl;
  static String? pendingTitle;

  static void prepare(
    final String tag, {
    final String? imageUrl,
    final String? title,
  }) {
    pendingTag = tag;
    if (imageUrl != null) pendingImageUrl = imageUrl;
    if (title != null) pendingTitle = title;
  }

  static Map<String, String> extra({
    final String? heroTag,
    final String? imageUrl,
    final String? title,
  }) {
    final String? tag = heroTag ?? pendingTag;
    final String? image = imageUrl ?? pendingImageUrl;
    final String? name = title ?? pendingTitle;
    if (tag != null) prepare(tag, imageUrl: image, title: name);
    return <String, String>{
      if (tag != null && tag.isNotEmpty) 'heroTag': tag,
      if (image != null && image.isNotEmpty) 'imageUrl': image,
      if (name != null && name.isNotEmpty) 'title': name,
    };
  }

  static String? field(final BuildContext context, final String key) {
    try {
      final Object? extra = GoRouterState.of(context).extra;
      if (extra is Map) {
        final Object? value = extra[key];
        if (value is String && value.isNotEmpty) return value;
      }
    } catch (_) {}
    return switch (key) {
      'heroTag' => pendingTag,
      'imageUrl' => pendingImageUrl,
      'title' => pendingTitle,
      _ => null,
    };
  }
}

/// Extra → uçuş yedeği → varsayılan etiket.
String resolveTiyatrolHeroTag(
  final BuildContext context,
  final String fallback,
) {
  Object? extra;
  try {
    extra = GoRouterState.of(context).extra;
  } catch (_) {
    extra = null;
  }
  if (extra is Map) {
    final Object? tag = extra['heroTag'];
    if (tag is String && tag.isNotEmpty) return tag;
  }
  final String? pending = TiyatrolHeroFlight.pendingTag;
  if (pending != null && pending.isNotEmpty) return pending;
  return fallback;
}

/// Afiş/portre paylaşılmış öğesi — Material yay yayı, 60fps transform.
class TiyatrolHero extends StatelessWidget {
  final String tag;
  final Widget child;

  const TiyatrolHero({
    super.key,
    required this.tag,
    required this.child,
  });

  @override
  Widget build(final BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return Hero(
      tag: tag,
      createRectTween: (final begin, final end) =>
          MaterialRectArcTween(begin: begin, end: end),
      flightShuttleBuilder: (
        final flightContext,
        final animation,
        final direction,
        final fromContext,
        final toContext,
      ) {
        final Hero toHero = toContext.widget as Hero;
        return toHero.child;
      },
      child: child,
    );
  }
}
