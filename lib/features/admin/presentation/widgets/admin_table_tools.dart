import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import 'admin_form_widgets.dart';

/// Admin katalog sekmelerinde paylaşılan arama çubuğu, filtre çipleri,
/// sıralanabilir tablo ve kart iskeleti. Sekmeler kendi sağlayıcı
/// listesini yerelde süzer; burada sahte veri üretilmez.

class AdminFilterOption {
  final String id;
  final String label;

  const AdminFilterOption({required this.id, required this.label});
}

class AdminFilterGroup {
  final String? heading;
  final List<AdminFilterOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const AdminFilterGroup({
    this.heading,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });
}

class AdminTableColumn<T> {
  final String id;
  final String label;
  final String Function(T item) text;
  final int Function(T a, T b) compare;
  final Widget Function(BuildContext context, T item)? cell;
  final bool numeric;

  const AdminTableColumn({
    required this.id,
    required this.label,
    required this.text,
    required this.compare,
    this.cell,
    this.numeric = false,
  });
}

bool adminQueryHits(final String query, final Iterable<String> fields) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return true;
  }
  for (final field in fields) {
    if (field.toLowerCase().contains(q)) {
      return true;
    }
  }
  return false;
}

int adminCompareText(final String a, final String b) =>
    a.toLowerCase().compareTo(b.toLowerCase());

int adminCompareDate(final String a, final String b) {
  final da = DateFormatter.parseDateString(a);
  final db = DateFormatter.parseDateString(b);
  if (da == null && db == null) {
    return a.compareTo(b);
  }
  if (da == null) {
    return 1;
  }
  if (db == null) {
    return -1;
  }
  return da.compareTo(db);
}

String adminFormatStamp(final String raw) {
  final parsed = DateFormatter.parseDateString(raw);
  if (parsed == null) {
    return raw.trim().isEmpty ? '—' : raw;
  }
  return DateFormat('dd.MM.yyyy HH:mm').format(parsed);
}

List<T> adminSorted<T>({
  required final List<T> items,
  required final List<AdminTableColumn<T>> columns,
  required final String sortColumnId,
  required final bool sortAscending,
}) {
  if (columns.isEmpty) {
    return List<T>.from(items);
  }
  final column = columns.firstWhere(
    (final c) => c.id == sortColumnId,
    orElse: () => columns.first,
  );
  final out = List<T>.from(items);
  out.sort((final a, final b) {
    final cmp = column.compare(a, b);
    return sortAscending ? cmp : -cmp;
  });
  return out;
}

/// Üst araç çubuğu: birincil "Yeni X" (varsa), arama, görünür/toplam
/// sayısı, gerçek alanlardan türetilmiş filtre çipleri.
class AdminListToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final int visibleCount;
  final int totalCount;
  final List<AdminFilterGroup> filterGroups;
  final String? primaryLabel;
  final String? primarySemantics;
  final VoidCallback? onPrimary;
  final IconData primaryIcon;
  final EdgeInsetsGeometry padding;

  const AdminListToolbar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.visibleCount,
    required this.totalCount,
    this.filterGroups = const [],
    this.primaryLabel,
    this.primarySemantics,
    this.onPrimary,
    this.primaryIcon = Icons.add_rounded,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final desktop = context.isDesktop;
    final hasPrimary = primaryLabel != null && onPrimary != null;

    final search = _AdminSearchField(
      controller: searchController,
      hint: searchHint,
    );
    final count = _AdminCountBadge(
      visible: visibleCount,
      total: totalCount,
    );
    final primary = hasPrimary
        ? AdminPrimaryButton(
            label: primaryLabel!,
            semanticsLabel: primarySemantics ?? primaryLabel!,
            icon: primaryIcon,
            onPressed: onPrimary!,
            expand: !desktop,
          )
        : null;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (desktop)
            Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: AppSpacing.md),
                count,
                if (primary != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  primary,
                ],
              ],
            )
          else ...[
            if (primary != null) ...[
              primary,
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: AppSpacing.sm),
                count,
              ],
            ),
          ],
          for (final group in filterGroups) ...[
            const SizedBox(height: AppSpacing.md),
            if (group.heading != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  group.heading!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            AdminFilterChipRow(group: group),
          ],
        ],
      ),
    );
  }
}

class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final String semanticsLabel;
  final VoidCallback onPressed;
  final IconData icon;
  final bool expand;

  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.expand = true,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final button = Semantics(
      button: true,
      label: semanticsLabel,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: expand ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
      ),
    );
    if (!expand) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}

class AdminFilterChipRow extends StatelessWidget {
  final AdminFilterGroup group;

  const AdminFilterChipRow({super.key, required this.group});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: group.options.map((final opt) {
        final selected = opt.id == group.selectedId;
        return Semantics(
          button: true,
          selected: selected,
          label: '${opt.label}${selected ? ', seçili' : ''}',
          child: FilterChip(
            label: Text(opt.label),
            selected: selected,
            onSelected: (final _) {
              HapticFeedback.selectionClick();
              group.onSelected(opt.id);
            },
            selectedColor: colors.primaryContainer,
            checkmarkColor: colors.onPrimaryContainer,
            backgroundColor: colors.surface,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
            ),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            showCheckmark: true,
          ),
        );
      }).toList(),
    );
  }
}

class AdminSortableTable<T> extends StatelessWidget {
  final List<T> items;
  final List<AdminTableColumn<T>> columns;
  final String sortColumnId;
  final bool sortAscending;
  final void Function({required String columnId, required bool ascending})
      onSort;
  final void Function(T item)? onRowTap;
  final String Function(T item) semanticLabel;

  const AdminSortableTable({
    super.key,
    required this.items,
    required this.columns,
    required this.sortColumnId,
    required this.sortAscending,
    required this.onSort,
    this.onRowTap,
    required this.semanticLabel,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final sortIndex = columns.indexWhere((final c) => c.id == sortColumnId);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppShadows.level1(colors.shadow),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: LayoutBuilder(
          builder: (final context, final constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(
                    colors.surfaceContainerHighest),
                dataRowMinHeight: 52,
                dataRowMaxHeight: 68,
                sortColumnIndex: sortIndex >= 0 ? sortIndex : null,
                sortAscending: sortAscending,
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  fontSize: 13,
                ),
                dataTextStyle: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                ),
                columns: [
                  for (var i = 0; i < columns.length; i++)
                    DataColumn(
                      label: Text(columns[i].label),
                      numeric: columns[i].numeric,
                      onSort: (final _, final ascending) => onSort(
                          columnId: columns[i].id, ascending: ascending),
                    ),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      onSelectChanged: onRowTap == null
                          ? null
                          : (final _) => onRowTap!(item),
                      cells: [
                        for (final col in columns)
                          DataCell(
                            Semantics(
                              button: true,
                              label: semanticLabel(item),
                              child: col.cell?.call(context, item) ??
                                  Text(
                                    col.text(item),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminEntityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String semanticLabel;
  final Widget? leading;

  const AdminEntityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.semanticLabel,
    this.leading,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminThumb extends StatelessWidget {
  final String imageUrl;
  final IconData fallback;

  const AdminThumb({
    super.key,
    required this.imageUrl,
    required this.fallback,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final placeholder = Container(
      width: 44,
      height: 44,
      color: colors.surfaceContainerHighest,
      child: Icon(fallback, color: colors.onSurfaceVariant, size: 20),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (final c, final e, final s) => placeholder,
            )
          : placeholder,
    );
  }
}

class AdminListLoading extends StatelessWidget {
  final int rows;

  const AdminListLoading({super.key, this.rows = 6});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: rows,
      separatorBuilder: (final _, final __) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (final context, final index) => AnimatedContainer(
        duration: AppMotion.fast,
        height: 64,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

class AdminEmptyList extends StatelessWidget {
  final String message;
  final bool isFiltered;

  const AdminEmptyList({
    super.key,
    required this.message,
    this.isFiltered = false,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off_rounded : Icons.inbox_outlined,
            color: colors.onSurfaceVariant,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isFiltered ? 'Arama veya filtreye uyan kayıt yok.' : message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class AdminListError extends StatelessWidget {
  final String message;

  const AdminListError({super.key, required this.message});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AdminInlineBanner(message: message),
        ),
      );
}

class AdminCatalogPane<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) cardBuilder;
  final Widget table;
  final bool shrinkWrap;

  const AdminCatalogPane({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.table,
    this.shrinkWrap = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (context.isDesktop) {
      if (shrinkWrap) {
        return table;
      }
      return Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: table,
        ),
      );
    }
    if (shrinkWrap) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            cardBuilder(items[i]),
          ],
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (final _, final __) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (final context, final index) => cardBuilder(items[index]),
    );
  }
}

class _AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _AdminSearchField({required this.controller, required this.hint});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.sm);
    return Semantics(
      textField: true,
      label: hint,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Temizle',
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          border: OutlineInputBorder(borderRadius: radius),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _AdminCountBadge extends StatelessWidget {
  final int visible;
  final int total;

  const _AdminCountBadge({required this.visible, required this.total});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Görünen $visible, toplam $total',
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Text(
          '$visible / $total',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }
}
