import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/custom_pop_up.dart';
import '../../features/login/presentation/providers/login_provider.dart';

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
      final success = await ref.read(loginProvider.notifier).signOut();
      if (context.mounted) Navigator.pop(context); // Loading'i kapat

      if (success)
        showSuccessDialog(context, 'Başarıyla çıkış yapıldı.');
      else
        showErrorDialog(context, 'Çıkış yapılırken bir sorun oluştu.');
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

    final confirmed = await _showArtConfirm(context, 'Hesabı Sil',
        'Tüm verileriniz kalıcı olarak silinecek. Emin misiniz?',
        isDanger: true);

    if (confirmed == true && context.mounted) {
      showLoading(context, "Hesabınız siliniyor...");
      final success = await ref.read(loginProvider.notifier).deleteAccount();
      if (context.mounted) Navigator.pop(context);

      if (success)
        showSuccessDialog(context, 'Hesabınız ve verileriniz silindi.');
      else
        showErrorDialog(context, 'Hesap silme işlemi başarısız oldu.');
    }
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
    await ref.read(loginProvider.notifier).verifyPhone(phone);
    if (context.mounted) Navigator.pop(context);

    final state = ref.read(loginProvider);
    if (state.isCodeSent)
      _showOtpDialog(context, ref);
    else
      showErrorDialog(context, state.errorMessage ?? 'Kod gönderilemedi.');
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
    final success = await ref.read(loginProvider.notifier).verifyOtp(code);
    if (context.mounted) Navigator.pop(context);

    if (success)
      showSuccessDialog(context, 'Telefon numaranız başarıyla bağlandı.');
    else
      showErrorDialog(context, 'Doğrulama kodu hatalı.');
  }
}

/// =======================================
/// 🔐 GOOGLE LINK HANDLER
/// =======================================
mixin ProfileGoogleLinkHandler on ProfileSnackBarHandler {
  Future<void> handleGoogleLink(
      final BuildContext context, final WidgetRef ref) async {
    showLoading(context, "Google ile bağlanılıyor...");
    final success = await ref.read(loginProvider.notifier).signInWithGoogle();
    if (context.mounted) Navigator.pop(context);

    if (success)
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
