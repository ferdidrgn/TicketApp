import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../users/domain/entities/favorite_type.dart';
import '../providers/favorite_provider.dart';

/// Show/Sahne/Sanatçı detaylarında ve kartlarda kullanılan, yeniden
/// kullanılabilir favori kalp butonu. Giriş yapılmamışsa login'e yönlendirir,
/// aksi halde Firestore'daki User.favoriteX listesini günceller.
class FavoriteToggleButton extends ConsumerWidget {
  final String itemId;
  final FavoriteType type;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const FavoriteToggleButton({
    super.key,
    required this.itemId,
    required this.type,
    this.size = 22,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider((itemId: itemId, type: type)));
    final isPending = ref.watch(favoriteMutationProvider
        .select((final pending) => pending.contains('${type.name}:$itemId')));

    final Widget icon = isPending
        ? SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: activeColor ?? Colors.redAccent,
            ),
          )
        : Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: size,
            color: isFavorite
                ? (activeColor ?? Colors.redAccent)
                : (inactiveColor ?? Colors.white),
          );

    final button = IconButton(
      padding: EdgeInsets.zero,
      icon: icon,
      onPressed: isPending ? null : () => _handleTap(context, ref),
    );

    if (backgroundColor == null) return button;

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: button,
    );
  }

  Future<void> _handleTap(final BuildContext context, final WidgetRef ref) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      NavigationHandler.goToLogin(context);
      return;
    }

    HapticFeedback.lightImpact();
    final success = await ref
        .read(favoriteMutationProvider.notifier)
        .toggle(itemId: itemId, type: type);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favori güncellenemedi, tekrar dene.')),
      );
    }
  }
}
