import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/push/notif_prefs_provider.dart';
import '../../core/theme/app_radius.dart';
import '../../shared/navigation/widgets/nav_handler.dart';
import '../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../shows/presentation/widgets/detail/show_detail_actions.dart'
    show ShowQuietIconButton;
import 'follow_logic.dart';

const String _offeredKey = 'follow_newshows_offered_v1';

/// Oturum açmış kullanıcının takip kümeleri (User belgesi, canlı).
final StreamProvider<Map<FollowKind, Set<String>>> followSetsProvider =
    StreamProvider<Map<FollowKind, Set<String>>>((final ref) {
  final String? uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(followSetsFromUser(null));
  return FirebaseFirestore.instance
      .collection('User')
      .doc(uid)
      .snapshots()
      .map((final s) => followSetsFromUser(s.data()));
});

/// Takip et — kalp ikonu korunur; etiket/ekran okuyucu "Takip et / Takibi bırak".
/// Yalnız `arrayUnion/arrayRemove` ile ilgili `User` alanını günceller.
/// İlk takipte (ve yalnız bildirim tercihi kapalıysa) tek seferlik, ONAYLI
/// "Yeni oyun bildirimlerini aç?" sayfası çıkar.
class FollowButton extends ConsumerStatefulWidget {
  final FollowKind kind;
  final String id;
  final bool onImage;

  const FollowButton(
      {super.key, required this.kind, required this.id, this.onImage = true});

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;

  Future<void> _toggle(final bool following) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final String? uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('Takip etmek için giriş yap.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Giriş yap',
            onPressed: () {
              if (mounted) NavigationHandler.goToLogin(context);
            },
          ),
        ));
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    bool failed = false;
    try {
      await FirebaseFirestore.instance.collection('User').doc(uid).update({
        widget.kind.field: following
            ? FieldValue.arrayRemove([widget.id])
            : FieldValue.arrayUnion([widget.id]),
      });
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(failed
            ? 'Takip kaydedilemedi. Bağlantını kontrol edip tekrar dene.'
            : (following ? 'Takibi bıraktın.' : 'Takip ediyorsun.')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    if (!failed && !following) await _maybeOffer();
  }

  Future<void> _maybeOffer() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final prefs = await ref.read(notifPrefsProvider.future);
    if (!mounted) return;
    if (!shouldOfferNewShows(
        alreadyOffered: sp.getBool(_offeredKey) ?? false, prefs: prefs)) {
      return;
    }
    await sp.setBool(_offeredKey, true);
    if (!mounted) return;
    final bool? yes = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (final ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yeni oyun bildirimlerini aç?',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                  'Takip ettiğin oyuncu, sahne ve toplulukların yeni oyunu ya da seansı olunca haber verelim. Ayarlar’dan istediğin zaman kapatabilirsin.'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Şimdi değil')),
                  const SizedBox(width: 8),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm))),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Aç')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true) {
      await ref
          .read(notifPrefsProvider.notifier)
          .change((final p) => p.copyWith(newShows: true));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final bool following = ref
            .watch(followSetsProvider)
            .value?[widget.kind]
            ?.contains(widget.id) ??
        false;
    return ShowQuietIconButton(
      icon: following ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      label: followLabel(following: following),
      onImage: widget.onImage,
      onPressed: _busy ? null : () => _toggle(following),
    );
  }
}
