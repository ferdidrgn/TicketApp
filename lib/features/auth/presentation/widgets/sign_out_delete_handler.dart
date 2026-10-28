import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../data/account_deletion_service.dart';
import '../providers/account_deletion_provider.dart';
import 'account_deletion_widgets.dart';

/// =======================================
/// 🔔 ORTAK DIALOG HANDLER (ARTISTIC)
/// =======================================
mixin ProfileSnackBarHandler {
  void showSuccessDialog(final BuildContext context, final String message,
          {final VoidCallback? onConfirm}) =>
      showDialog(
        context: context,
        builder: (final _) =>
            CustomSuccessDialog(message: message, onConfirm: onConfirm),
      );

  void showErrorDialog(final BuildContext context, final String message) =>
      showDialog(
        context: context,
        builder: (final _) => CustomErrorDialog(message: message),
      );

  void showLoading(final BuildContext context, final String message) =>
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (final _) => CustomLoadingDialog(message: message),
      );
}

/// =======================================
/// 🚪 SIGN OUT HANDLER
/// =======================================
mixin ProfileSignOutHandler on ProfileSnackBarHandler {
  Future<void> showSignOutDialog(
      final BuildContext context, final WidgetRef ref) async {
    final confirmed = await _showArtConfirm(
        context, 'Çıkış Yap', 'Oturumunuz sonlandırılacak. Emin misiniz?');

    if (confirmed == true && context.mounted) {
      showLoading(context, "Oturum kapatılıyor...");
      await ref.read(authMutationProvider.notifier).signOut();
      if (context.mounted) Navigator.pop(context); // Loading'i kapat
    }
  }
}

/// =======================================
/// 🗑️ DELETE ACCOUNT HANDLER
/// =======================================
mixin ProfileDeleteAccountHandler on ProfileSnackBarHandler {
  Future<void> showDeleteAccountDialog(final BuildContext context,
      final WidgetRef ref, final String userId) async {
    if (userId.isEmpty) {
      showErrorDialog(context, 'Kullanıcı kimliği doğrulanamadı.');
      return;
    }

    // Önizleme tarihi; kesin tarih sunucu cevabıyla bildirilir.
    final preview =
        DateTime.now().add(const Duration(days: kAccountDeletionGraceDays));
    final confirmed = await _showArtConfirm(
        context, 'Hesabı Sil', deletionConfirmMessage(preview),
        isDanger: true);
    if (confirmed != true || !context.mounted) return;

    showLoading(context, 'İstek gönderiliyor...');
    final outcome = await ref.read(accountDeletionControllerProvider).request();
    if (context.mounted) Navigator.pop(context); // Loading'i kapat
    if (!context.mounted) return;

    switch (outcome) {
      case DeletionBlocked(:final reason):
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (final sheetContext) => UpcomingTicketsSheet(
            reason: reason,
            onGoToTickets: () {
              Navigator.pop(sheetContext);
              NavigationHandler.goToMyTickets(context, userId);
            },
          ),
        );
      case DeletionAlreadyPending():
        showSuccessDialog(context,
            'Hesabınız zaten silinmek üzere. Üstteki şeritten silmeyi iptal edebilirsiniz.');
      case DeletionFailed(:final message):
        showErrorDialog(context, message);
      case DeletionScheduled(:final date):
        await _finishAndLeave(
            context,
            ref,
            date == null
                ? 'Silme isteğiniz alındı. Bu süre içinde giriş yapıp vazgeçebilirsiniz.'
                : deletionConfirmMessage(date));
      case DeletionDone():
        await _finishAndLeave(context, ref, 'Hesabınız silindi.');
    }
  }

  Future<void> _finishAndLeave(final BuildContext context, final WidgetRef ref,
      final String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (final dialogContext) => AlertDialog(
        title: const Text('Hesap silme'),
        content: Text(message),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tamam')),
        ],
      ),
    );
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    // Mevcut çıkış akışı: FCM token temizliği + yerel veri + Firebase çıkışı.
    // Silme işini sunucu yapar; storage/Firestore temizliği istemcide YOK.
    await ref.read(authMutationProvider.notifier).signOut();
    router.go('/login');
  }
}

/// =======================================
/// 📲 PHONE LINK HANDLER
/// =======================================
mixin ProfilePhoneLinkHandler on ProfileSnackBarHandler {
  void showPhoneLinkDialog(final BuildContext context, final WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (final _) => AlertDialog(
        title: const Text('Telefon Bağla'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+905xxxxxxxxx'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startPhoneLink(context, ref, controller.text.trim());
            },
            child: const Text('Kod Gönder'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPhoneLink(final BuildContext context, final WidgetRef ref,
      final String phone) async {
    showLoading(context, "Kod gönderiliyor...");
    await ref.read(authMutationProvider.notifier).verifyPhone(phone);
    if (context.mounted) Navigator.pop(context);

    final state = ref.read(authMutationProvider);
    if (!state.hasError)
      _showOtpDialog(context, ref);
    else
      showErrorDialog(context, state.error.toString());
  }

  void _showOtpDialog(final BuildContext context, final WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (final _) => AlertDialog(
        title: const Text('Doğrulama Kodu'),
        content: TextField(
            controller: controller,
            maxLength: 6,
            keyboardType: TextInputType.number),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _verifyOtp(context, ref, controller.text.trim());
            },
            child: const Text('Doğrula'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOtp(final BuildContext context, final WidgetRef ref,
      final String code) async {
    showLoading(context, "Doğrulanıyor...");
    await ref.read(authMutationProvider.notifier).verifyOtp(code);
    if (context.mounted) Navigator.pop(context);

    final state = ref.read(authMutationProvider);
    if (!state.hasError)
      showSuccessDialog(context, 'Telefon numaranız başarıyla bağlandı.');
    else
      showErrorDialog(context, 'Doğrulama kodu hatalı veya geçersiz.');
  }
}

/// =======================================
/// 🔐 GOOGLE LINK HANDLER
/// =======================================
mixin ProfileGoogleLinkHandler on ProfileSnackBarHandler {
  Future<void> handleGoogleLink(
      final BuildContext context, final WidgetRef ref) async {
    showLoading(context, "Google ile bağlanılıyor...");
    await ref.read(authMutationProvider.notifier).signInWithGoogle();
    if (context.mounted) Navigator.pop(context);

    final state = ref.read(authMutationProvider);
    if (!state.hasError)
      showSuccessDialog(context, 'Google hesabınız bağlandı.');
    else
      showErrorDialog(context, 'Bağlantı sırasında bir hata oluştu.');
  }
}

/// =======================================
/// 🛠 UTILS (Confirm Dialog)
/// =======================================
Future<bool?> _showArtConfirm(
        final BuildContext context, final String title, final String msg,
        {final bool isDanger = false}) =>
    showDialog<bool>(
      context: context,
      builder: (final _) => AlertDialog(
        title: Text(title,
            style: TextStyle(
                color: isDanger ? Colors.red : null,
                fontWeight: FontWeight.bold)),
        content: Text(msg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.red : null,
              foregroundColor: isDanger ? Colors.white : null,
            ),
            child: Text(title),
          ),
        ],
      ),
    );
