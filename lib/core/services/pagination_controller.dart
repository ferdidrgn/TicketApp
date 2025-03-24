class PaginationController<T> {
  final List<T> allItems;
  final int itemsPerPage;
  int currentPage = 1;
  bool hasMoreItems = true;

  PaginationController({
    required this.allItems,
    this.itemsPerPage = 10,
  });

  List<T> get currentItems {
    final startIndex = 0;
    final endIndex = currentPage * itemsPerPage;
    if (endIndex >= allItems.length) {
      hasMoreItems = false;
      return allItems;
    }
    return allItems.sublist(startIndex, endIndex);
  }

  void loadMoreItems() {
    if (hasMoreItems) currentPage++;
  }

  void reset() {
    currentPage = 1;
    hasMoreItems = true;
  }
}
