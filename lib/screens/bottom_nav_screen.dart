import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; // Ensure this is imported
import 'package:unipantry/screens/grocery_screen.dart';
import 'package:unipantry/screens/home_screen.dart';
import 'package:unipantry/screens/manual_entry_screen.dart';
import 'package:unipantry/screens/profile_screen.dart';
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
    GroceryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // The Modal for Adding Items
  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Add New Item',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Scan Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsDuotone.qrCode, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Scan Barcode', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Scan product packaging'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              
              // Manual Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsDuotone.pencilSimple, color: Theme.of(context).colorScheme.secondary),
                ),
                title: const Text('Add Manually', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Type item details manually'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0, // Flat look
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
        destinations: [
          NavigationDestination(
            icon: Icon(PhosphorIconsDuotone.house),
            selectedIcon: Icon(PhosphorIconsFill.house),
            label: 'Pantry',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsDuotone.shoppingCart),
            selectedIcon: Icon(PhosphorIconsFill.shoppingCart),
            label: 'Grocery',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsDuotone.user),
            selectedIcon: Icon(PhosphorIconsFill.user),
            label: 'Profile',
          ),
        ],
      ),
      
      // --- CUSTOMIZED FLOATING ACTION BUTTON ---
      floatingActionButton: _selectedIndex == 0
          ? SizedBox(
              height: 64, // Slightly larger than default 56
              width: 64,
              child: FloatingActionButton(
                onPressed: _showAddItemModal,
                tooltip: 'Add Item',
                elevation: 2, // Subtle shadow
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                // The "Squircle" Shape
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25), 
                ),
                child: const Icon(PhosphorIconsDuotone.plus, size: 30),
              ),
            )
          : null,
    );
  }
}