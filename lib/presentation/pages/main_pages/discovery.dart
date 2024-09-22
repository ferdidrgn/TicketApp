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
    _fetchEventsByCategory();
  }

  Future<void> _fetchEventsByCategory() async {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomSectionTitle(title: 'Keşfet', fontSize: 22),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterPopup(context),
                ),
              ],
            ),
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

  Widget _buildScrollableItems(List<Show?> items) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
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
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrele',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              _buildCategoryFilter(),
              _buildPriceRangeFilter(),
              _buildDateRangePicker(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchEventsByCategory(); // Fetch with new filters
                },
                child: const Text('Uygula'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    List<String> categories = ['Müzik', 'Tiyatro', 'Sinema', 'Dans', 'Opera'];
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
                  setState(() {
                    if (selectedCategories.contains(category)) {
                      selectedCategories.remove(category);
                    } else {
                      selectedCategories.add(category);
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: selectedCategories.contains(category)
                        ? Colors.blue
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
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

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fiyat Aralığı'),
        RangeSlider(
          values: RangeValues(minPrice, maxPrice),
          min: 0,
          max: 5200,
          divisions: 10,
          onChanged: (RangeValues values) {
            setState(() {
              minPrice = values.start;
              maxPrice = values.end;
            });
          },
        ),
        Text(
          '₺${minPrice.toStringAsFixed(2)} - ₺${maxPrice.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tarih Aralığı Seçin'),
        ElevatedButton(
          onPressed: () async {
            DateTime? newStartDate = await showDatePicker(
              context: context,
              initialDate: startDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            setState(() {
              startDate = newStartDate;
            });
          },
          child: Text(
              'Başlangıç: ${startDate?.toLocal().toString().split(' ')[0] ?? 'Seçin'}'),
        ),
        ElevatedButton(
          onPressed: () async {
            DateTime? newEndDate = await showDatePicker(
              context: context,
              initialDate: endDate ?? DateTime.now(),
              firstDate: startDate ?? DateTime(2020),
              lastDate: DateTime(2100),
            );
            setState(() {
              endDate = newEndDate;
            });
          },
          child: Text(
              'Bitiş: ${endDate?.toLocal().toString().split(' ')[0] ?? 'Seçin'}'),
        ),
      ],
    );
  }
}
