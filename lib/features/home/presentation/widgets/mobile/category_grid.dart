import 'package:flutter/material.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  static const _categories = [
    CategoryData(
      icon: Icons.theater_comedy,
      label: 'Tiyatro',
      color: Color(0xFFFFB7B2),
    ),
    CategoryData(
      icon: Icons.music_note,
      label: 'Konser',
      color: Color(0xFFE2F0CB),
    ),
    CategoryData(
      icon: Icons.mic_external_on,
      label: 'Stand-up',
      color: Color(0xFFFFDAC1),
    ),
    CategoryData(
      icon: Icons.museum,
      label: 'Müze',
      color: Color(0xFFC7CEEA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          return _CategoryItem(category: _categories[index]);
        },
      ),
    );
  }
}

class CategoryData {
  final IconData icon;
  final String label;
  final Color color;

  const CategoryData({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _CategoryItem extends StatelessWidget {
  final CategoryData category;

  const _CategoryItem({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.6),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: category.color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Icon(
            category.icon,
            color: Colors.black87,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category.label,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
