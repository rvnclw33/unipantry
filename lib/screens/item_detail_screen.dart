import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  
  // --- State for Editable Fields ---
  late String _selectedUnit;
  late DateTime _expiryDate;

  final List<String> _units = ['pcs', 'kg', 'g', 'L', 'ml', 'pack', 'can', 'bottle'];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item.description);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _selectedUnit = widget.item.unit;
    _expiryDate = widget.item.expiryDate; // Initialize with current expiry
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // --- NEW: Date Picker Logic ---
  Future<void> _pickNewExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: now.subtract(const Duration(days: 365)), // Allow correcting past dates
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  // --- Save Logic ---
  void _saveChanges() async {
    final newQty = int.tryParse(_quantityController.text) ?? widget.item.quantity;
    
    // Create updated item object
    final updatedItem = widget.item.copyWith(
      description: _descriptionController.text,
      quantity: newQty,
      unit: _selectedUnit,
      expiryDate: _expiryDate, // Save the new date
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
    final theme = Theme.of(context);
    
    // Calculate color for the date display
    final daysLeft = _expiryDate.difference(DateTime.now()).inDays;
    Color dateColor = Colors.black;
    if (daysLeft < 0) dateColor = Colors.red;
    else if (daysLeft <= 3) dateColor = Colors.orange;
    else dateColor = Colors.green;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Edit Item'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
            icon: Icon(PhosphorIconsDuotone.check, color: theme.colorScheme.primary, size: 28),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsDuotone.package, size: 32, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name, 
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                      ),
                      Text(
                        widget.item.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- 1. Expiry Date Editor ---
            Text("Expiry Date", style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickNewExpiryDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dateColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsDuotone.calendar, color: dateColor),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMMd().format(_expiryDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          daysLeft < 0 ? "Expired" : "Expires in $daysLeft days",
                          style: TextStyle(color: dateColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(PhosphorIconsDuotone.pencilSimple, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Quantity & Unit ---
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      prefixIcon: Icon(PhosphorIconsDuotone.hash),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      prefixIcon: Icon(PhosphorIconsDuotone.ruler),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- 3. Description / Notes ---
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Icon(PhosphorIconsDuotone.note),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),

            const SizedBox(height: 32),
            
            // --- Barcode Info (Read Only) ---
            if (widget.item.barcode != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scanned Barcode: ${widget.item.barcode}',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}