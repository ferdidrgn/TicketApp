import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';

class CategoryCardBuilder extends StatelessWidget {
  final List<Map<String, Object>>? categories;

  const CategoryCardBuilder({super.key, this.categories});

  @override
  Widget build(final BuildContext context) {
    // Use default categories if the provided list is null
    final List<Map<String, Object>> effectiveCategories =
        categories?.isNotEmpty == true
            ? categories!
            : [
                {'title': 'Tümünü Keşfet', 'icon': Icons.explore},
                {'title': 'Trendler', 'icon': Icons.trending_up},
                {'title': 'Tiyatro', 'icon': Icons.theater_comedy},
                {'title': 'Konser', 'icon': Icons.library_music},
                {'title': 'Stand Up', 'icon': Icons.event_seat_rounded},
                {'title': 'Festival', 'icon': Icons.festival_rounded},
                {'title': 'Sinema', 'icon': Icons.movie_filter_rounded},
                {'title': 'Çocuk', 'icon': Icons.family_restroom},
                {'title': 'Spor', 'icon': Icons.sports_baseball},
                {'title': 'Etkinlik', 'icon': Icons.event},
              ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: effectiveCategories.map((final category) {
          return _buildCategoryCard(
            category['title'].toString(),
            category['icon']! as IconData,
            context,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(final String title, final IconData icon,
          final BuildContext context) =>
      InkWell(
          onTap: () {
            NavigationHandler.goToDiscoverWithCategory(context, title);
          },
          child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: Card(
                  elevation: 8,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon,
                                size: 50,
                                color: context.isDarkMode
                                    ? Colors.white
                                    : Colors.red),
                            const SizedBox(height: 10),
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal))
                          ])))));
}
