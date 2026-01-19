import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../core/localization/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  final bool isDrawer;

  const LanguageSelector({super.key, this.isDrawer = false});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final localeAsync = ref.watch(localeControllerProvider);
    final currentLocale = localeAsync.value ?? const Locale('tr');

    // Ortak dil seçenekleri listesi
    final List<({Locale locale, String label, String flag})> languages = [
      (locale: const Locale('tr'), label: 'Türkçe', flag: '🇹🇷'),
      (locale: const Locale('en'), label: 'English', flag: '🇺🇸'),
    ];

    // --- DRAWER TASARIMI (Yan Menü) ---
    if (isDrawer) {
      return ExpansionTile(
        leading: Icon(Icons.translate_rounded, color: context.colors.primary),
        title: Text(
          currentLocale.languageCode == 'tr' ? 'Dil Seçimi' : 'Language',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          languages.firstWhere((final e) => e.locale == currentLocale).label,
          style: TextStyle(color: context.colors.primary, fontSize: 12),
        ),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        children: languages.map((final lang) {
          final isSelected = currentLocale == lang.locale;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            leading: Text(lang.flag, style: const TextStyle(fontSize: 20)),
            title: Text(lang.label),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded,
                    color: context.colors.primary, size: 20)
                : null,
            onTap: () => ref
                .read(localeControllerProvider.notifier)
                .setLocale(lang.locale),
          );
        }).toList(),
      );
    }

    // --- APPBAR TASARIMI (Üst Menü - Popup) ---
    return PopupMenuButton<Locale>(
      tooltip: 'Language',
      offset: const Offset(0, 45),
      // Menüyü butonun biraz altına indirir
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.colors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.translate_rounded,
          color: context.colors.primary,
          size: context.responsive(mobile: 22, tablet: 24, desktop: 26),
        ),
      ),
      onSelected: (final Locale locale) {
        ref.read(localeControllerProvider.notifier).setLocale(locale);
      },
      itemBuilder: (final context) => languages.map((final lang) {
        final isSelected = currentLocale == lang.locale;
        return PopupMenuItem<Locale>(
          value: lang.locale,
          child: Row(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lang.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? context.colors.primary : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded,
                    color: context.colors.primary, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }
}
