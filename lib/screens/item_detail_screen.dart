import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unipantry/models/food_item.dart';
import 'package:unipantry/providers/food_provider.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final FoodItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late String _selectedUnit;
  
  // List of available units
  final List<String> _units = ['pcs', 'kg', 'g', 'L', 'ml', 'pack', 'can'];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item.description);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _selectedUnit = widget.item.unit;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final newQty = int.tryParse(_quantityController.text) ?? widget.item.quantity;
    
    // Create updated item object
    final updatedItem = widget.item.copyWith(
      description: _descriptionController.text,
      quantity: newQty,
      unit: _selectedUnit,
    );

    // Update in Firestore
    await ref.read(foodServiceProvider).updateFoodItem(updatedItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            onPressed: _saveChanges,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.fastfood, size: 30, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.name, style: Theme.of(context).textTheme.headlineSmall),
                      Text('Added: ${DateFormat.yMMMd().format(widget.item.addedAt)}',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40),

            // Barcode Info Section
            if (widget.item.barcode != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Scanned Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          Text('Barcode: ${widget.item.barcode}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Edit Quantity & Unit
            const Text('Quantity & Unit', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Qty',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Unit',
                    ),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description / Notes Field
            const Text('Description / Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: widget.item.barcode != null 
                    ? 'Add details about this scanned product...' 
                    : 'Add notes, recipe ideas, or storage tips...',
              ),
            ),
            
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete Item', style: TextStyle(color: Colors.red)),
                onPressed: () {
                   // Implement delete logic here if needed, or stick to swipe-to-delete
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}