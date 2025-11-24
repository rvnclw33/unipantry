import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/food_provider.dart';
import 'package:unipantry/widgets/app_drawer.dart'; // Ensure you created this file
import 'package:unipantry/widgets/food_card.dart';

// Your existing filter enum
enum FoodFilter { all, expiringSoon, expired }

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
  String _selectedCategory = 'All';

  // --- Helper to show delete confirmation ---
  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to remove this item from your pantry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), // No
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true), // Yes
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodItemsAsync = ref.watch(foodItemsStreamProvider(_currentFoodFilter));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // --- 1. ADD THE DRAWER ---
      drawer: const AppDrawer(),
      
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // --- 2. HEADER WITH HAMBURGER BUTTON ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Use Builder to get the correct context to open drawer
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(PhosphorIconsDuotone.list, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'My Pantry',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 3. SEGMENTED EXPIRY FILTER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton('All', FoodFilter.all),
                    _buildSegmentButton('Expiring', FoodFilter.expiringSoon),
                    _buildSegmentButton('Expired', FoodFilter.expired),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // --- 4. CATEGORY HORIZONTAL LIST ---
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: isSelected 
                            ? null 
                            : Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected 
                                ? theme.colorScheme.onPrimary 
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),

            // --- 5. FOOD ITEM LIST WITH SWIPE-TO-DELETE ---
            Expanded(
              child: foodItemsAsync.when(
                data: (items) {
                  // Client-side category filtering
                  final filteredList = items.where((item) {
                    if (_selectedCategory == 'All') return true;
                    return item.category == _selectedCategory;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];

                      // --- DISMISSIBLE WRAPPER ---
                      return Dismissible(
                        key: Key(item.id), // Unique Key is critical
                        direction: DismissDirection.endToStart, // Swipe R to L
                        
                        // Background (Red "Delete" reveal)
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white, size: 28),
                        ),
                        
                        // Confirm Dialog
                        confirmDismiss: (direction) async {
                          return await _showDeleteConfirmation(context);
                        },

                        // Actual Delete Action
                        onDismissed: (direction) {
                          // Call the delete method in your provider
                          ref.read(foodServiceProvider).deleteFoodItem(item.id);
                          
                          // Optional snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  // NOTE: To implement real undo, you'd need to re-add the item here
                                  ref.read(foodServiceProvider).addFoodItem(item);
                                },
                              ),
                            ),
                          );
                        },

                        child: FoodCard(item: item),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsDuotone.package, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String text, FoodFilter filter) {
    final isSelected = _currentFoodFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentFoodFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected 
                  ? Theme.of(context).colorScheme.onSurface 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}