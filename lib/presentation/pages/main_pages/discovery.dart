import 'package:flutter/material.dart';
import 'package:ticketapp/core/custom_views/custom_title.dart';
import '../../../core/custom_views/custom_event_card.dart';
import '../../../data/model/show.dart';
import '../../../data/repository/show_service.dart';

class DiscoveryPage extends StatefulWidget {
  final String? selectedCategory;

  const DiscoveryPage({super.key, this.selectedCategory});

  @override
  _DiscoveryPageState createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  bool isLoading = true;
  List<Show?> shows = [];
  List<String> selectedCategories = [];
  String? type;
  double minPrice = 0;
  double maxPrice = 5200;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategory != null &&
        widget.selectedCategory != 'Tümünü Keşfet' &&
        widget.selectedCategory != 'Trendler') {
      selectedCategories.add(widget.selectedCategory!);
    }
    _fetchEventsByCategory();
  }

  Future<void> _fetchEventsByCategory() async {
    setState(() => isLoading = true);

    try {
      final showService = ShowService();
      final List<Show?> fetchedEvents =
          await showService.getSearchShow(selectedCategories, type);
      setState(() {
        shows = fetchedEvents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      throw Exception('Veriler çekilirken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : shows.isEmpty
                    ? const Center(
                        child: Text('Bu kategori için etkinlik bulunamadı.'))
                    : Expanded(child: _buildScrollableItems(shows)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CustomSectionTitle(title: 'Keşfet', fontSize: 22),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterPopup(context),
        ),
      ],
    );
  }

  Widget _buildScrollableItems(List<Show?> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return EventCard(
          imageUrl: items[index]?.imageUrl ?? '',
          showName: items[index]?.name ?? '',
          category: items[index]?.category ?? '',
          date: "15.06.2023",
          stage: "Sahne 1",
          price: 150.0,
        );
      },
    );
  }

  void _showFilterPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtrele',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildCategoryFilter(setModalState),
                  const SizedBox(height: 20),
                  _buildPriceRangeFilter(setModalState),
                  const SizedBox(height: 20),
                  _buildDateRangePicker(setModalState),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchEventsByCategory(); // Yeni filtrelerle verileri çek
                    },
                    child: Text('Uygula',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryFilter(StateSetter setModalState) {
    final List<String> categories = [
      'Tiyatro',
      'Konser',
      'Festival',
      'Sinema',
      'Çocuk',
      'Spor',
      'Etkinlik'
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
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    selectedCategories.contains(category)
                        ? selectedCategories.remove(category)
                        : selectedCategories.add(category);
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: selectedCategories.contains(category)
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
        const SizedBox(height: 10),
        Text('Seçilen Kategoriler: ${selectedCategories.join(', ')}'),
      ],
    );
  }

  Widget _buildPriceRangeFilter(StateSetter setModalState) {
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
          onChanged: (values) {
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

  Widget _buildDateRangePicker(StateSetter setModalState) {
    final themeOf = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tarih Aralığı Seçin'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () async {
                DateTime? newStartDate = await showDatePicker(
                  context: context,
                  initialDate: startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: themeOf.copyWith(
                        colorScheme: ColorScheme.light(
                          primary: themeOf.colorScheme.error,
                          // Seçili tarih butonlarının rengi
                          onPrimary: themeOf.colorScheme.onPrimary,
                          // Seçili tarih buton yazı rengi
                          surface: themeOf.colorScheme.secondary,
                          // Diyalog arka plan rengi
                          onSurface: themeOf.colorScheme
                              .onSurface, // Tarihlerin varsayılan yazı rengi
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: themeOf.colorScheme
                                .onSurface, //butonlarının yazı rengi
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                setModalState(() => startDate = newStartDate);
              },
              child: Text(
                  'Başlangıç: ${startDate?.toLocal().toString().split(' ')[0] ?? 'Seçin'}',
                  style: TextStyle(color: themeOf.colorScheme.onSurface)),
            ),
            ElevatedButton(
              onPressed: () async {
                DateTime? newEndDate = await showDatePicker(
                  context: context,
                  initialDate: endDate ?? DateTime.now(),
                  firstDate: startDate ?? DateTime(2020),
                  lastDate: DateTime(2100),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: themeOf.copyWith(
                        colorScheme: ColorScheme.light(
                          primary: themeOf.colorScheme.error,
                          // Seçili tarih butonlarının rengi
                          onPrimary: themeOf.colorScheme.onPrimary,
                          // Seçili tarih buton yazı rengi
                          surface: themeOf.colorScheme.secondary,
                          // Diyalog arka plan rengi
                          onSurface: themeOf.colorScheme
                              .onSurface, // Tarihlerin varsayılan yazı rengi
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: themeOf.colorScheme
                                .onSurface, //butonlarının yazı rengi
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                setModalState(() => endDate = newEndDate);
              },
              child: Text(
                  'Bitiş: ${endDate?.toLocal().toString().split(' ')[0] ?? 'Seçin'}',
                  style: TextStyle(color: themeOf.colorScheme.onSurface)),
            ),
          ],
        ),
      ],
    );
  }
}
