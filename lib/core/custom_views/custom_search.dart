import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;

  const CustomSearchBar({super.key, this.onSearchTap, this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5, // Adds shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(10), // Matches the Card border
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(10), // Matches the Card border
            ),
            hintText: 'Etkinlikleri Ara...',
            hintStyle: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            prefixIcon: IconButton(
              icon: const Icon(Icons.youtube_searched_for),
              onPressed: onSearchTap,
            ),
          ),
          onTap: onSearchTap,
          onChanged: onSearchChanged,
        )
    );
  }
}