import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';

/// Admin panelindeki tüm formlarda tekrar eden küçük parçalar — internal
/// bir araç olduğu için "Perde açıldı" görsel dilinden (curtain/spotlight)
/// bilinçli olarak kaçınır, ama renk/`AppSpacing`/`AppRadius`/`AppShadows`
/// token kurallarını tam uygular (bkz. CLAUDE.md).

/// Bölüm başlığı — form içindeki grupları ayırır.
class AdminSectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;

  const AdminSectionTitle({super.key, required this.title, this.icon});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            top: AppSpacing.xl, bottom: AppSpacing.sm),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              title.toUpperCase(),
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
}

/// Basit, gerçek Firestore dokümanlarından beslenen dropdown alanı
/// (Team/Stage seçimi gibi). Boş/yükleniyor durumları çağıran tarafından
/// yönetilir — bu widget sadece dolu bir liste aldığında gösterilir.
class AdminDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const AdminDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDarkMode;
    final borderColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black12;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: context.primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor:
              isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

/// Görsel seçici — kare önizleme + "değiştir" rozeti. Hem yeni bir
/// `File` (henüz yüklenmemiş) hem de mevcut bir `imageUrl` (ağdan) ile
/// çalışır. Gerçek `image_picker` akışı çağıran ekranda (`onPick`).
class AdminImagePickerField extends StatelessWidget {
  final File? selectedFile;
  final String? existingImageUrl;
  final VoidCallback onPick;
  final String semanticLabel;

  const AdminImagePickerField({
    super.key,
    required this.selectedFile,
    required this.existingImageUrl,
    required this.onPick,
    required this.semanticLabel,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final hasImage =
        selectedFile != null || (existingImageUrl?.isNotEmpty ?? false);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPick,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: AppShadows.level1(colors.shadow),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (selectedFile != null)
                Image.file(selectedFile!, fit: BoxFit.cover)
              else if (existingImageUrl != null && existingImageUrl!.isNotEmpty)
                Image.network(existingImageUrl!, fit: BoxFit.cover,
                    errorBuilder: (final c, final e, final s) => Icon(
                        Icons.image_not_supported_rounded,
                        color: colors.onSurfaceVariant))
              else
                Center(
                  child: Icon(Icons.add_photo_alternate_rounded,
                      size: 40, color: colors.onSurfaceVariant),
                ),
              Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: AppSpacing.xs),
                      Text(hasImage ? 'Değiştir' : 'Görsel Seç',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Basit bir "sonuç" banner'ı — inline hata/başarı geri bildirimi için
/// (dialog yerine, form içinde kalıcı bir satır gerektiğinde).
class AdminInlineBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const AdminInlineBanner(
      {super.key, required this.message, this.isError = true});

  @override
  Widget build(final BuildContext context) {
    final color = isError ? Colors.red : Colors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(message, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}
