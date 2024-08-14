import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  CartPage({super.key});

  final List<Ticket> tickets =
      []; // Bu listeyi doldurarak sepetin dolu ya da boş olmasını simüle edebilirsiniz.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sepetim'),
      ),
      body:
          tickets.isEmpty ? _buildEmptyCart(context) : _buildCartList(context),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Sepetiniz Boş',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
            ),
            onPressed: () {
              // Gösterileri görüntüle butonuna basıldığında yapılacak işlem
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child:
                  Text('Gösterileri Görüntüle', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(BuildContext context) {
    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.all(10),
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tickets[index].name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Yaş Sınırı: ${tickets[index].ageRestriction}'),
                Text('Fiyat: ${tickets[index].price} TL'),
                Text('Adet: ${tickets[index].quantity}'),
                Text(
                    'Koltuk Numaraları: ${tickets[index].seatNumbers.join(', ')}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class Ticket {
  final String name;
  final String ageRestriction;
  final double price;
  final int quantity;
  final List<String> seatNumbers;

  Ticket(
      {required this.name,
      required this.ageRestriction,
      required this.price,
      required this.quantity,
      required this.seatNumbers});
}
