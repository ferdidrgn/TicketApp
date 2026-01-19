extension StringSlug on String {
  String toSlug() => toLowerCase()
      .replaceAll(' ', '-')
      .replaceAll('ş', 's')
      .replaceAll('ı', 'i')
      .replaceAll('ç', 'c')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ğ', 'g')
      .replaceAll(RegExp(r'[^a-z0-9-]'), '');
}
