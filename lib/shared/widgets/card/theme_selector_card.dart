import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_context_extension.dart';
import '../../../core/theme/theme_notifier.dart';

class ThemeSelectorCard extends ConsumerWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = context.colors;
    final currentTheme = ref.watch(themeProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEMA TERCİHİ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ThemeButton(
                label: 'Açık',
                mode: ThemeMode.light,
                icon: Icons.wb_sunny_rounded,
                isActive: currentTheme == ThemeMode.light,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
              ),
              const SizedBox(width: 10),
              _ThemeButton(
                label: 'Koyu',
                mode: ThemeMode.dark,
                icon: Icons.nights_stay_rounded,
                isActive: currentTheme == ThemeMode.dark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
              ),
              const SizedBox(width: 10),
              _ThemeButton(
                label: 'Sistem',
                mode: ThemeMode.system,
                icon: Icons.phone_iphone_rounded,
                isActive: currentTheme == ThemeMode.system,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sadece bu dosya içinde kullanılacak özel mini buton widget'ı
class _ThemeButton extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.label,
    required this.mode,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 45,
          decoration: BoxDecoration(
            color: isActive ? theme.primary : theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : theme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : theme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : theme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
