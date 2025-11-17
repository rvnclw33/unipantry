// lib/screens/bottom_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:unipantry/screens/home_screen.dart';
import 'package:unipantry/screens/manual_entry_screen.dart';
import 'package:unipantry/screens/scan_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;

  // Define the pages
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    // Placeholder screens for your other features
    Center(child: Text('Grocery Screen (To Be Built)')),
    Center(child: Text('Profile Screen (To Be Built)')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // THIS IS THE MODAL YOU ASKED FOR
  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan Barcode'),
                onTap: () {
                  Navigator.pop(ctx); // Close the modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Add Manually'),
                onTap: () {
                  Navigator.pop(ctx); // Close the modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManualEntryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Use "fixed" to show labels on all items
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'My Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Grocery List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemModal,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}