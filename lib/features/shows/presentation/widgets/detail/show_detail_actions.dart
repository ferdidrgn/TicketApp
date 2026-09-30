import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/ticket/stage_moments.dart';
import '../../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../../../../users/presentation/providers/user_mutation_provider.dart';
import '../../../../users/presentation/providers/user_provider.dart'
    show userProfileProvider;
import '../../../domain/entities/show.dart';

/// İkincil aksiyonlar için sessiz, yuvarlak ikon butonu (geri, paylaş,
/// favori). 48dp dokunma alanı, tooltip + ekran okuyucu etiketi, görünür
/// klavye odağı. [onImage] → afişin üstünde (koyu yarı saydam zemin, beyaz
/// ikon); değilse temanın yüzey rengi.
class ShowQuietIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool onImage;
  final Color? iconColor;

  const ShowQuietIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.onImage = false,
    this.iconColor,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final Color fg = iconColor ?? (onImage ? Colors.white : colors.onSurface);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: fg,
          backgroundColor: onImage
              ? Colors.black.withOpacity(0.38)
              : colors.surfaceContainerHighest.withOpacity(0.92),
          focusColor: colors.primary.withOpacity(0.24),
          hoverColor: fg.withOpacity(0.08),
          side: onImage
              ? BorderSide(color: Colors.white.withOpacity(0.22))
              : BorderSide(color: colors.outlineVariant.withOpacity(0.6)),
        ),
      ),
    );
  }
}

/// Geri butonu — `NavigationHandler.smartGoBack` (uygulamanın ortak geri
/// mantığı).
class ShowBackButton extends StatelessWidget {
  final bool onImage;
  const ShowBackButton({super.key, this.onImage = false});

  @override
  Widget build(final BuildContext context) => ShowQuietIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Geri dön',
        onImage: onImage,
        onPressed: () => NavigationHandler.smartGoBack(context),
      );
}

/// Paylaş — gerçek derin bağlantı (`TiyatrolDeeplinkService.shareShow`).
class ShowShareButton extends StatelessWidget {
  final Show show;
  final bool onImage;
  const ShowShareButton({super.key, required this.show, this.onImage = false});

  @override
  Widget build(final BuildContext context) => ShowQuietIconButton(
        icon: Icons.ios_share_rounded,
        label: 'Bu oyunu paylaş',
        onImage: onImage,
        onPressed: () =>
            TiyatrolDeeplinkService.shareShow(id: show.id, name: show.name),
      );
}

/// Favori — önceden mobilde boş bir `onPressed: () {}` idi (sahte
/// aksiyon). Artık kullanıcının GERÇEK `User.favoriteShows` listesini
/// profil kaydıyla aynı yoldan (`userMutationProvider.save`) günceller;
/// Favoriler ekranı bu listeyi zaten okuyor. Giriş yapılmamışsa kullanıcı
/// sayfadan atılmaz, "Giriş yap" aksiyonlu bir bildirim görür.
class ShowFavoriteButton extends ConsumerStatefulWidget {
  final String showId;
  final bool onImage;

  const ShowFavoriteButton(
      {super.key, required this.showId, this.onImage = false});

  @override
  ConsumerState<ShowFavoriteButton> createState() => _ShowFavoriteButtonState();
}

class _ShowFavoriteButtonState extends ConsumerState<ShowFavoriteButton> {
  /// Kaydedilirken anında geri bildirim için iyimser değer.
  bool? _optimistic;
  bool _saving = false;

  Future<void> _toggle(final bool current) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final String? uid = ref.read(currentUserIdProvider);
    final user = ref.read(userProfileProvider).value;
    if (uid == null || user == null) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('Favorilere eklemek için giriş yap.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          action: SnackBarAction(
            label: 'Giriş yap',
            onPressed: () {
              if (mounted) NavigationHandler.goToLogin(context);
            },
          ),
        ));
      return;
    }
    if (_saving) return;

    final bool next = !current;
    final List<String> favorites =
        user.favoriteShows.where((final id) => id != widget.showId).toList();
    if (next) favorites.add(widget.showId);

    setState(() {
      _optimistic = next;
      _saving = true;
    });
    // Sahneye gül: favoriye eklemenin küçük keyif anı (sadece eklerken).
    if (next) tossRose(context);
    await ref.read(userMutationProvider.notifier).save(
          user.copyWith(favoriteShows: favorites),
          user.imageUrl,
          isUpdate: true,
        );
    if (!mounted) return;
    final bool failed = ref.read(userMutationProvider).hasError;
    setState(() {
      _saving = false;
      if (failed) _optimistic = current;
    });
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(failed
            ? 'Favori kaydedilemedi. Bağlantını kontrol edip tekrar dene.'
            : (next
                ? 'Sahneye gülünü attın — favorilere eklendi.'
                : 'Favorilerden çıkarıldı.')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ));
  }

  @override
  Widget build(final BuildContext context) {
    // Kayıt sürerken mutasyon sağlayıcısı (autoDispose) canlı kalsın ve
    // hata durumu okunabilsin.
    ref.watch(userMutationProvider);
    final List<String>? saved =
        ref.watch(userProfileProvider).value?.favoriteShows;
    final bool fromProfile = saved?.contains(widget.showId) ?? false;
    // Profil yeniden yüklenip gerçek değer iyimser değere yetişince iyimser
    // değer bırakılır.
    if (_optimistic != null && !_saving && _optimistic == fromProfile) {
      _optimistic = null;
    }
    final bool isFavorite = _optimistic ?? fromProfile;

    return ShowQuietIconButton(
      icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      label: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
      onImage: widget.onImage,
      iconColor: isFavorite
          ? (widget.onImage ? Colors.white : context.colors.primary)
          : null,
      onPressed: _saving ? null : () => _toggle(isFavorite),
    );
  }
}

/// Başka platformda satılan oyunun bilet sayfasını açar. Açılamazsa
/// kullanıcıya ne olduğunu söyler (sessizce yutmak yerine).
Future<void> openExternalTickets(
    final BuildContext context, final String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final Uri? uri = Uri.tryParse(url.trim());
  bool opened = false;
  if (uri != null) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened) {
    messenger?.showSnackBar(const SnackBar(
      content: Text('Bilet sayfası açılamadı. Birazdan tekrar dene.'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
