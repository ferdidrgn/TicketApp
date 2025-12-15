import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../events/presentation/widgets/events_card.dart';
import '../../../../shared/widgets/custom_title.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  List<String> selectedCategories = [];
  double minPrice = 0;
  double maxPrice = 5200;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.selectedCategory != null &&
        widget.selectedCategory != 'Tümünü Keşfet' &&
        widget.selectedCategory != 'Trendler')
      selectedCategories.add(widget.selectedCategory!);

    _fetchData();
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      final shows = ref.read(showProvider).dataList;
      if (shows == null || shows.isEmpty)
        ref.read(showProvider.notifier).searchShows(selectedCategories, null);
    });
  }

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            if (showState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (showState.hasError)
              Center(child: Text(showState.errorMessage ?? 'Bir hata oluştu'))
            else if (showState.dataList?.isEmpty ?? true)
              Text('Bu kategori için etkinlik bulunamadı.',
                  style: textTheme.bodyMedium)
            else
              Expanded(child: _buildEventList(showState.dataList!)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CustomSectionTitle(title: 'Keşfet'),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterPopup(context),
        ),
      ],
    );
  }

  Widget _buildEventList(final List<Show> shows) {
    return ListView.builder(
      itemCount: shows.length,
      itemBuilder: (final context, final index) {
        final show = shows[index];
        return EventsCard(
          imageUrl: show.imageUrl,
          showName: show.name,
          category: show.category,
          date: "15.06.2023",
          stage: "Sahne 1",
          price: 150.0,
        );
      },
    );
  }

  void _showFilterPopup(final BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (final context) {
        return StatefulBuilder(
          builder: (final context, final setModalState) {
            return FilterBottomSheet(
              selectedCategories: selectedCategories,
              minPrice: minPrice,
              maxPrice: maxPrice,
              startDate: startDate,
              endDate: endDate,
              setModalState: setModalState,
              onApplyFilters: (final filters) {
                setState(() {
                  selectedCategories = filters.selectedCategories;
                  minPrice = filters.minPrice;
                  maxPrice = filters.maxPrice;
                  startDate = filters.startDate;
                  endDate = filters.endDate;
                });
                Navigator.pop(context);
                _fetchData();
              },
            );
          },
        );
      },
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final List<String> selectedCategories;
  final double minPrice;
  final double maxPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(void Function()) setModalState;
  final Function(FilterData) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.selectedCategories,
    required this.minPrice,
    required this.maxPrice,
    this.startDate,
    this.endDate,
    required this.setModalState,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> selectedCategories;
  late double minPrice;
  late double maxPrice;
  late DateTime? startDate;
  late DateTime? endDate;

  @override
  void initState() {
    super.initState();
    selectedCategories = List.from(widget.selectedCategories);
    minPrice = widget.minPrice;
    maxPrice = widget.maxPrice;
    startDate = widget.startDate;
    endDate = widget.endDate;
  }

  Widget _buildCategoryFilter(final StateSetter setModalState) {
    final categories = [
      'Tiyatro',
      'Konser',
      'Festival',
      'Sinema',
      'Çocuk',
      'Spor',
      'Etkinlik',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori Seçin'),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (final context, final index) {
              final category = categories[index];
              final isSelected = selectedCategories.contains(category);

              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    isSelected
                        ? selectedCategories.remove(category)
                        : selectedCategories.add(category);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(right: 5, top: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).focusColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(child: Text(category)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        Text('Seçilen Kategoriler: ${selectedCategories.join(', ')}'),
      ],
    );
  }

  Widget _buildPriceRangeFilter(final StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fiyat Aralığı'),
        RangeSlider(
          values: RangeValues(minPrice, maxPrice),
          min: 0,
          max: 5200,
          divisions: 10,
          activeColor: Theme.of(context).colorScheme.error,
          inactiveColor: Theme.of(context).focusColor,
          onChanged: (final values) {
            setModalState(() {
              minPrice = values.start;
              maxPrice = values.end;
            });
          },
        ),
        Text(
            '₺${minPrice.toStringAsFixed(2)} - ₺${maxPrice.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildDateRangePicker(final StateSetter setModalState) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tarih Aralığı Seçin'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () async {
                final newStartDate = await showDatePicker(
                  context: context,
                  initialDate: startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (final context, final child) => Theme(
                    data: theme.copyWith(
                      colorScheme: ColorScheme.light(
                        primary: theme.colorScheme.error,
                        onPrimary: theme.colorScheme.onPrimary,
                        surface: theme.colorScheme.secondary,
                        onSurface: theme.colorScheme.onSurface,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface),
                      ),
                    ),
                    child: child!,
                  ),
                );
                setModalState(() => startDate = newStartDate);
              },
              child: Text(
                'Başlangıç: ${startDate?.toLocal().toString().split(' ')[0] ?? 'Seçin'}',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newEndDate = await showDatePicker(
                  context: context,
                  initialDate: endDate ?? DateTime.now(),
                  firstDate: startDate ?? DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (final context, final child) => Theme(
                    data: theme.copyWith(
                      colorScheme: ColorScheme.light(
                        primary: theme.colorScheme.error,
                        onPrimary: theme.colorScheme.onPrimary,
                        surface: theme.colorScheme.secondary,
                        onSurface: theme.colorScheme.onSurface,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface),
                      ),
                    ),
                    child: child!,
                  ),
                );
                setModalState(() => endDate = newEndDate);
              },
              child: Text(
                'Bitiş: ${endDate?.toLocal().toString().split(' ')[0] ?? 'Seçin'}',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomSectionTitle(
              title: "Filitrele", fontWeight: FontWeight.bold),
          const SizedBox(height: 20),
          _buildCategoryFilter(widget.setModalState),
          const SizedBox(height: 20),
          _buildPriceRangeFilter(widget.setModalState),
          const SizedBox(height: 20),
          _buildDateRangePicker(widget.setModalState),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onApplyFilters(
                FilterData(
                  selectedCategories: selectedCategories,
                  minPrice: minPrice,
                  maxPrice: maxPrice,
                  startDate: startDate,
                  endDate: endDate,
                ),
              );
            },
            child: CustomSectionTitle(
                title: 'Uygula',
                fontSize: 20,
                textColor: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                alignment: Alignment.center),
          ),
        ],
      ),
    );
  }
}

class FilterData {
  final List<String> selectedCategories;
  final double minPrice;
  final double maxPrice;
  final DateTime? startDate;
  final DateTime? endDate;

  FilterData({
    required this.selectedCategories,
    required this.minPrice,
    required this.maxPrice,
    this.startDate,
    this.endDate,
  });
}
