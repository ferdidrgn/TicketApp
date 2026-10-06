import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/responsive_utils.dart';
import 'auth_ticket.dart';

/// Dokunuş geri bildirimi — yalnızca mobil/tablet cihaz (web'de yok).
void authHapticLight() {
  if (kIsWeb) return;
  HapticFeedback.lightImpact();
}

void authHapticSelection() {
  if (kIsWeb) return;
  HapticFeedback.selectionClick();
}

/// Masaüstü web'de hover; mobil/tablet'te ≥48dp dokunma alanı.
bool authUseThumbTargets(final BuildContext context) =>
    !ResponsiveUtils.isDesktop(context);

/// Ham hata → kullanıcıya ne oldu (özür yok, teknik dump yok).
String authErrorMessage(final Object error) {
  if (error is Failure) return error.message;

  if (error is FirebaseAuthException) {
    return _firebaseAuthMessage(error);
  }

  var raw = error.toString();
  if (raw.startsWith('Exception: ')) raw = raw.substring(11);
  if (raw.startsWith('FirebaseAuthException')) {
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(raw);
    if (match != null) {
      return _firebaseCodeMessage(match.group(1)!, raw);
    }
  }

  final lower = raw.toLowerCase();
  if (lower.contains('network') ||
      lower.contains('internet') ||
      lower.contains('bağlantı')) {
    return 'İnternet bağlantısı yok. Bağlantını kontrol edip tekrar dene.';
  }
  if (lower.contains('popup-closed') || lower.contains('vazgeç')) {
    return 'Google penceresi kapatıldı. Tekrar deneyebilirsin.';
  }

  return raw.trim().isEmpty ? 'İşlem tamamlanamadı.' : raw.trim();
}

String _firebaseAuthMessage(final FirebaseAuthException e) =>
    _firebaseCodeMessage(e.code, e.message ?? '');

String _firebaseCodeMessage(final String code, final String fallback) {
  switch (code) {
    case 'network-request-failed':
      return 'İnternet bağlantısı yok. Bağlantını kontrol edip tekrar dene.';
    case 'invalid-verification-code':
      return 'Kod hatalı. SMS\'teki 6 haneyi kontrol et.';
    case 'session-expired':
    case 'code-expired':
      return 'Kodun süresi doldu. Yeni kod iste.';
    case 'too-many-requests':
      return 'Çok fazla deneme. Biraz bekle, sonra tekrar dene.';
    case 'invalid-phone-number':
      return 'Telefon numarası geçersiz. 10 hane, başında 0 olmadan.';
    case 'operation-not-allowed':
      return 'Bu giriş yöntemi şu an kapalı.';
    case 'credential-already-in-use':
      return 'Bu hesap başka bir profile bağlı.';
    case 'user-disabled':
      return 'Bu hesap devre dışı.';
    case 'popup-closed-by-user':
      return 'Google penceresi kapatıldı. Tekrar deneyebilirsin.';
    default:
      final msg = fallback.trim();
      if (msg.isNotEmpty && !msg.startsWith('[')) return msg;
      return 'Giriş tamamlanamadı ($code). Tekrar dene.';
  }
}

/// [TicketStampButton] + haptic; yüklemede çift basma kapalı.
class AuthStampButton extends StatelessWidget {
  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;
  final String? loadingLabel;

  const AuthStampButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.primary = true,
    this.loading = false,
    this.loadingLabel,
  });

  @override
  Widget build(final BuildContext context) {
    final bool thumb = authUseThumbTargets(context);
    // Birincil damga zaten 56dp; ikincil 50dp — mobil kuralına uygun.
    final Widget stamp = TicketStampButton(
      label: label,
      leading: leading,
      primary: primary,
      loading: loading,
      loadingLabel: loadingLabel,
      onTap: onTap == null || loading
          ? onTap
          : () {
              authHapticLight();
              onTap!();
            },
    );

    if (!thumb) {
      return MouseRegion(
        cursor: onTap != null && !loading
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: stamp,
      );
    }

    return stamp;
  }
}

/// Misafir / ikincil metin aksiyonu — web hover, mobil 48dp başparmak alanı.
class AuthGuestLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const AuthGuestLink({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  State<AuthGuestLink> createState() => _AuthGuestLinkState();
}

class _AuthGuestLinkState extends State<AuthGuestLink> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    if (widget.loading) {
      return SizedBox(
        height: authUseThumbTargets(context) ? 48 : 32,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: TicketInk.accentOf(context),
            ),
          ),
        ),
      );
    }

    final bool thumb = authUseThumbTargets(context);

    Widget link = TicketTextLink(
      label: widget.label,
      onTap: widget.onTap == null
          ? null
          : () {
              authHapticSelection();
              widget.onTap!();
            },
      emphasize: true,
    );

    if (!thumb && kIsWeb) {
      link = AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _hovered ? 1 : 0.88,
        child: link,
      );
    }

    return MouseRegion(
      onEnter: thumb ? null : (_) => setState(() => _hovered = true),
      onExit: thumb ? null : (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: thumb
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Center(child: link),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: link,
            ),
    );
  }
}

/// Telefon adımındaki alt metin linkleri (düzenle / yeniden gönder).
class AuthTouchLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool emphasize;

  const AuthTouchLink({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasize = false,
  });

  @override
  Widget build(final BuildContext context) {
    final bool thumb = authUseThumbTargets(context);
    final link = TicketTextLink(
      label: label,
      onTap: onTap == null
          ? null
          : () {
              authHapticSelection();
              onTap!();
            },
      emphasize: emphasize,
    );

    if (!thumb) {
      return MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: link,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Align(alignment: Alignment.centerLeft, child: link),
    );
  }
}

void showAuthErrorSnackBar(
  final BuildContext context, {
  required final String message,
  final VoidCallback? onRetry,
  final double? width,
}) {
  if (!context.mounted) return;
  final cs = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: cs.onError)),
      backgroundColor: cs.error,
      behavior: SnackBarBehavior.floating,
      width: width,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      action: onRetry == null
          ? null
          : SnackBarAction(
              label: 'Tekrar dene',
              textColor: cs.onError,
              onPressed: onRetry,
            ),
    ),
  );
}
