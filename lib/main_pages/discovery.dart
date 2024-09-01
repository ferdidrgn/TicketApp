import 'package:flutter/material.dart';
import 'package:ticketapp/custom_views/custom_event_card.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  _DiscoveryPageState createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  // Sample data for events
  final List<Event> events = [
    Event(
      imageUrl: 'https://via.placeholder.com/150',
      showName: 'Konser 1',
      category: 'Müzik',
      date: '2024-09-15',
      stage: 'Sahne 1',
      price: 100,
    ),
    Event(
      imageUrl: 'https://via.placeholder.com/150',
      showName: 'Tiyatro 1',
      category: 'Tiyatro',
      date: '2024-09-20',
      stage: 'Sahne 2',
      price: 75,
    ),
    // Add more events here
  ];

  // Filter values
  String selectedCategory = 'Müzik';
  double minPrice = 0;
  double maxPrice = 5200;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));

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
                _buildSectionTitle('Keşfet Etkinlikler'),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterPopup(),
                ),
              ],
            ),
            Expanded(
              child: _buildScrollableItems(events),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterPopup() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterDropdown(
                  'Kategori',
                  ['Müzik', 'Tiyatro', 'Sinema', 'Dans', 'Opera'],
                  selectedCategory, (newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              }),
              _buildPriceRangeSlider(),
              _buildDateRangePicker(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Apply filter logic if needed
                },
                child: const Text('Uygula'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown(String title, List<String> options,
      String selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        value: selectedValue,
        onChanged: onChanged,
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceRangeSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fiyat Aralığı'),
          RangeSlider(
            values: RangeValues(minPrice, maxPrice),
            min: 0,
            max: 5200,
            divisions: 10,
            onChanged: (values) {
              setState(() {
                minPrice = values.start;
                maxPrice = values.end;
              });
            },
          ),
          Text(
              '₺${minPrice.toStringAsFixed(2)} - ₺${maxPrice.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tarih Aralığı'),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    DateTime? newStartDate = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (newStartDate != null && newStartDate != startDate) {
                      setState(() {
                        startDate = newStartDate;
                      });
                    }
                  },
                  child: Text(
                      'Başlangıç: ${startDate.toLocal().toShortDateString()}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    DateTime? newEndDate = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime(2100),
                    );
                    if (newEndDate != null && newEndDate != endDate) {
                      setState(() {
                        endDate = newEndDate;
                      });
                    }
                  },
                  child:
                      Text('Bitiş: ${endDate.toLocal().toShortDateString()}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildScrollableItems(List<Event> items) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return EventCard(
          imageUrl: items[index].imageUrl,
          showName: items[index].showName,
          category: items[index].category,
          date: items[index].date,
          stage: items[index].stage,
          price: items[index].price,
        );
      },
    );
  }
}

class Event {
  final String imageUrl;
  final String showName;
  final String category;
  final String date;
  final String stage;
  final double price;

  Event({
    required this.imageUrl,
    required this.showName,
    required this.category,
    required this.date,
    required this.stage,
    required this.price,
  });
}

extension DateFormatting on DateTime {
  String toShortDateString() {
    return '${this.day}-${this.month}-${this.year}';
  }
}
