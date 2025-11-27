import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/food_provider.dart';
import 'package:unipantry/widgets/app_drawer.dart';
import 'package:unipantry/widgets/food_card.dart';

// --- ENUMS ---
// Make sure this DeleteAction enum includes 'mistake'
enum DeleteAction { cancel, consumed, wasted, mistake }

const List<String> _categories = [
  'All', 'Fruit', 'Vegetable', 'Meat', 'Dairy', 
  'Bakery', 'Pantry', 'Drinks', 'Other'
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  FoodFilter _currentFoodFilter = FoodFilter.all;
  String _selectedCategory = 'All';

  // --- NEW: Smart Delete Dialog ---
  Future<DeleteAction?> _showDeleteActionDialog(BuildContext context, String itemName) {
    return showDialog<DeleteAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $itemName?'),
        content: const Text('Why are you removing this item?'),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowButtonSpacing: 8,
        actions: [
          // 1. The Tracking Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDialogOption(
                ctx, 
                label: 'Consumed', 
                icon: PhosphorIconsDuotone.check, 
                color: Colors.green, 
                action: DeleteAction.consumed
              ),
              _buildDialogOption(
                ctx, 
                label: 'Wasted', 
                icon: PhosphorIconsDuotone.trash, 
                color: Colors.red, 
                action: DeleteAction.wasted
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          
          // 2. The "Oops" Option (Mistake)
          TextButton(
            onPressed: () => Navigator.pop(ctx, DeleteAction.mistake),
            child: const Text("Just remove (Mistake entry)", style: TextStyle(color: Colors.grey)),
          ),
          
          // 3. Cancel
          TextButton(
            onPressed: () => Navigator.pop(ctx, DeleteAction.cancel),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  // Helper for big dialog buttons
  Widget _buildDialogOption(BuildContext context, {required String label, required IconData icon, required Color color, required DeleteAction action}) {
    return InkWell(
      onTap: () => Navigator.pop(context, action),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodItemsAsync = ref.watch(foodItemsStreamProvider(_currentFoodFilter));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
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

            // Expiry Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(4),
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

            // Category Filter
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

            // --- LIST WITH DISMISSIBLE ---
            Expanded(
              child: foodItemsAsync.when(
                data: (items) {
                  final filteredList = items.where((item) {
                    if (_selectedCategory == 'All') return true;
                    return item.category == _selectedCategory;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        
                        // Background (Reveal)
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(PhosphorIconsDuotone.trash, color: theme.colorScheme.error, size: 28),
                        ),
                        
                        // --- CONFIRM DISMISS LOGIC ---
                        confirmDismiss: (direction) async {
                          final action = await _showDeleteActionDialog(context, item.name);
                          
                          if (action == DeleteAction.consumed) {
                            // Positive Action: Just delete
                            ref.read(foodServiceProvider).deleteFoodItem(item.id);
                            return true;
                          } 
                          else if (action == DeleteAction.wasted) {
                            // Negative Action: Log to waste, then delete
                            ref.read(foodServiceProvider).logWastedItem(item);
                            return true;
                          } 
                          else if (action == DeleteAction.mistake) {
                            // Neutral Action: Just delete, no tracking
                            ref.read(foodServiceProvider).deleteFoodItem(item.id);
                            return true;
                          }
                          
                          // Cancel
                          return false;
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
          padding: const EdgeInsets.symmetric(vertical: 6),
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