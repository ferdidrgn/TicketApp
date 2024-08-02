import 'package:flutter/material.dart';
import 'cart_page.dart';
import 'events_page.dart';
import 'profile_page.dart';
import 'home_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class HomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const HomePage({super.key, required this.onThemeChanged});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      const HomeScreen(),
      CartPage(),
      EventsPage(),
      ProfilePage(onThemeChanged: widget.onThemeChanged),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilet Satış Uygulaması'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor!,
        color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor!,
        buttonBackgroundColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor!,
        height: 50,
        items: const <Widget>[
          Icon(Icons.home, size: 30),
          Icon(Icons.shopping_cart, size: 30),
          Icon(Icons.event, size: 30),
          Icon(Icons.people, size: 30),
        ],
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        index: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}