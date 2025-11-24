// grocery screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/grocery_provider.dart';

class GroceryScreen extends ConsumerStatefulWidget {
  const GroceryScreen({super.key});

  @override
  ConsumerState<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends ConsumerState<GroceryScreen> {
  // We capture the internal controller and focus node from Autocomplete
  TextEditingController? _autocompleteController;
  FocusNode? _autocompleteFocusNode; 

  // --- Add Item Logic ---
  void _addItem(String value) {
    if (value.trim().isEmpty) return;
    
    // Add to database
    ref.read(groceryActionsProvider).addItem(value.trim());
    
    // Clear the text field
    _autocompleteController?.clear();
    
    // Request focus on the CAPTURED node to keep keyboard open
    _autocompleteFocusNode?.requestFocus();
  }

  // --- Checkout Dialog ---
  void _showCheckoutDialog(BuildContext context, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$count Items Selected'),
        content: const Text(
          'What would you like to do with these items?',
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(groceryActionsProvider).deleteCompleted();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Items deleted')),
                );
              }
            },
            icon: Icon(PhosphorIconsDuotone.trash, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final movedCount = await ref.read(groceryActionsProvider).checkoutCompletedItems();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Moved $movedCount items to Pantry!')),
                );
              }
            },
            icon: Icon(PhosphorIconsDuotone.check),
            label: const Text('To Pantry'),
          ),
        ],
      ),
    );
  }

  // --- Group Items Helper ---
  Map<String, List<GroceryItem>> _groupItems(List<GroceryItem> items) {
    final Map<String, List<GroceryItem>> groups = {};
    for (var item in items) {
      final key = item.isChecked ? 'Done' : item.category;
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groceryListAsync = ref.watch(groceryStreamProvider);
    final theme = Theme.of(context);
    final actions = ref.read(groceryActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          groceryListAsync.when(
            data: (items) {
              final checkedCount = items.where((i) => i.isChecked).length;
              if (checkedCount > 0) {
                return TextButton.icon(
                  onPressed: () => _showCheckoutDialog(context, checkedCount),
                  icon: Icon(PhosphorIconsDuotone.basket, color: theme.colorScheme.primary),
                  label: Text('Actions ($checkedCount)', 
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. INTELLIGENT AUTOCOMPLETE ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue val) {
                if (val.text == '') return const Iterable<String>.empty();
                return actions.getSuggestions(val.text);
              },
              
              onSelected: (String selection) {
                _addItem(selection);
              },

              // THE FIX IS HERE:
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // 1. Capture the values provided by Autocomplete
                _autocompleteController = controller;
                _autocompleteFocusNode = focusNode; 
                
                return TextField(
                  controller: controller,
                  focusNode: focusNode, // 2. MUST use this specific focusNode
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Add item (e.g. Apple)',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    prefixIcon: Icon(Icons.add, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (val) {
                    _addItem(val);
                  },
                );
              },

              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // --- 2. CATEGORIZED LIST ---
          Expanded(
            child: groceryListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsDuotone.shoppingCart, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("Your list is empty", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final grouped = _groupItems(items);
                final categories = grouped.keys.toList()
                  ..sort((a, b) {
                    if (a == 'Done') return 1;
                    if (b == 'Done') return -1;
                    return a.compareTo(b);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 40),
                  itemCount: categories.length,
                  itemBuilder: (ctx, index) {
                    final category = categories[index];
                    final categoryItems = grouped[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              color: category == 'Done' ? Colors.green : theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...categoryItems.map((item) => Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red.shade400,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            actions.deleteItem(item.id);
                          },
                          child: CheckboxListTile(
                            title: Text(
                              item.name,
                              style: TextStyle(
                                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                color: item.isChecked ? Colors.grey : null,
                              ),
                            ),
                            value: item.isChecked,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (_) => actions.toggleItem(item.id, item.isChecked),
                            controlAffinity: ListTileControlAffinity.leading,
                            visualDensity: VisualDensity.compact,
                          ),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}