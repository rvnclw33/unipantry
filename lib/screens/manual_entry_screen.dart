// lib/screens/manual_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipantry/models/food_item.dart';
import 'package:unipantry/providers/food_provider.dart';
import 'package:unipantry/services/notification_service.dart';
import 'package:intl/intl.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  // We can pass in data from the ScanScreen
  final String? scannedItemName;
  final String? scannedBrand;
  final String? scannedBarcode;

  const ManualEntryScreen({
    super.key,
    this.scannedItemName,
    this.scannedBrand,
    this.scannedBarcode,
  });

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all our new fields
  late final TextEditingController _nameController;
  final _quantityController = TextEditingController(text: '1');
  final _brandController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedExpiryDate;
  String? _selectedCategory; // For the dropdown

  // Mock list of categories. You could move this to a constants file.
  final List<String> _categories = [
    'Fruit',
    'Vegetable',
    'Meat',
    'Dairy',
    'Bakery',
    'Pantry',
    'Drinks',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if they came from the scanner
    _nameController =
        TextEditingController(text: widget.scannedItemName ?? '');
    _brandController.text = widget.scannedBrand ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    setState(() {
      _selectedExpiryDate = pickedDate;
    });
  }

  void _saveItem() {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      // Form has errors
      return;
    }

    if (_selectedExpiryDate == null) {
      // Show error if no date is picked
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiry date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Form is valid and date is picked, create the new item
    final newItem = FoodItem(
      id: '', // Firestore will generate this
      name: _nameController.text,
      category: _selectedCategory!,
      quantity: int.parse(_quantityController.text),
      expiryDate: _selectedExpiryDate!,
      addedAt: DateTime.now(),
      brand: _brandController.text.isNotEmpty ? _brandController.text : null,
      storageLocation: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      barcode: widget.scannedBarcode, // From the scanner
    );

    // Use the food provider to add the item
    ref.read(foodServiceProvider).addFoodItem(newItem);

    // Show a local notification
    NotificationService().showNotification(
      title: 'Item Added!',
      body: '${newItem.name} was added to your pantry.',
    );

    // Go back to the main screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.scannedItemName != null ? 'Confirm Item' : 'Add Manually'),
      ),
      body: SingleChildScrollView( // Added to prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Item Name ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fastfood),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an item name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Category Dropdown ---
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Category'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category.' : null,
                ),
                const SizedBox(height: 16),

                // --- Quantity ---
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.stacked_line_chart),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a quantity.';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Must be a positive number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- Expiry Date Picker ---
                Text(
                  'Expiry Date',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedExpiryDate == null
                            ? 'No expiry date chosen'
                            : 'Expires: ${DateFormat.yMd().format(_selectedExpiryDate!)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _presentDatePicker,
                      child: const Text('Choose Date'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // --- Optional Fields ---
                Text(
                  'Optional Info',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // --- Brand ---
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Storage Location ---
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Save Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveItem,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Item'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}