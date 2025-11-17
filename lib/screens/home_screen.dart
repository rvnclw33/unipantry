// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipantry/providers/food_provider.dart';
import 'package:unipantry/widgets/food_card.dart';

// Your existing filter enum
enum FoodFilter { all, expiringSoon, expired }

// Your mock categories. This should match the list in the entry form.
// 'All' is added for filtering.
const List<String> _categories = [
  'All',
  'Fruit',
  'Vegetable',
  'Meat',
  'Dairy',
  'Bakery',
  'Pantry',
  'Drinks',
  'Other'
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  FoodFilter _currentFoodFilter = FoodFilter.all;
  String _selectedCategory = 'All'; // NEW: For category filtering

  @override
  Widget build(BuildContext context) {
    // Watch the stream provider. Riverpod handles loading/error states
    final foodItemsAsync = ref.watch(foodItemsStreamProvider(_currentFoodFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
      ),
      body: Column(
        children: [
          // --- 1. FOOD EXPIRY FILTER ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text('All Items'),
                  selected: _currentFoodFilter == FoodFilter.all,
                  onSelected: (selected) {
                    if (selected)
                      setState(() => _currentFoodFilter = FoodFilter.all);
                  },
                ),
                FilterChip(
                  label: const Text('Expiring Soon'),
                  selected: _currentFoodFilter == FoodFilter.expiringSoon,
                  onSelected: (selected) {
                    if (selected)
                      setState(() => _currentFoodFilter = FoodFilter.expiringSoon);
                  },
                ),
                FilterChip(
                  label: const Text('Expired'),
                  selected: _currentFoodFilter == FoodFilter.expired,
                  onSelected: (selected) {
                    if (selected)
                      setState(() => _currentFoodFilter = FoodFilter.expired);
                  },
                ),
              ],
            ),
          ),

          // --- 2. NEW: CATEGORY FILTER CHIPS ---
          Container(
            height: 50,
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // --- 3. UPDATED: FOOD ITEM LIST ---
          Expanded(
            child: foodItemsAsync.when(
              data: (items) {
                // --- NEW: Apply the category filter on the client side ---
                // This is simple but less efficient for 1000s of items.
                // For a real-world app, you'd add this filter to the Firebase query.
                final filteredList = items.where((item) {
                  if (_selectedCategory == 'All') {
                    return true; // Show all items
                  }
                  return item.category == _selectedCategory;
                }).toList();
                
                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text('No items found in this category.'),
                  );
                }

                // Build the list using our new FoodCard
                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    // Use the new FoodCard widget
                    return FoodCard(item: item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: ${err.toString()}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}