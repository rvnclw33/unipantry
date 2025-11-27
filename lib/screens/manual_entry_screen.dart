import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/models/food_item.dart';
import 'package:unipantry/providers/food_provider.dart';
import 'package:unipantry/services/notification_service.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  final String? scannedItemName;
  final String? scannedBrand;
  final String? scannedBarcode;
  final String? scannedDescription;

  const ManualEntryScreen({
    super.key,
    this.scannedItemName,
    this.scannedBrand,
    this.scannedBarcode,
    this.scannedDescription,
  });

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final _quantityController = TextEditingController(text: '1');
  final _brandController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedExpiryDate;
  String? _selectedCategory;
  String _selectedUnit = 'pcs';

  final List<String> _categories = [
    'Fruit', 'Vegetable', 'Meat', 'Seafood','Dairy', 
    'Bakery', 'Snacks', 'Drinks', 'Other'
  ];

  final List<String> _units = [
    'pcs', 'kg', 'g', 'L', 'ml', 'pack', 'can', 'bottle'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scannedItemName ?? '');
    _brandController.text = widget.scannedBrand ?? '';
    if (widget.scannedDescription != null) {
      _descriptionController.text = widget.scannedDescription!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- NEW: Logic to increment/decrement quantity ---
  void _updateQuantity(int change) {
    int current = int.tryParse(_quantityController.text) ?? 1;
    int newValue = current + change;
    
    // Prevent going below 1
    if (newValue < 1) newValue = 1;
    
    setState(() {
      _quantityController.text = newValue.toString();
    });
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
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
    if (pickedDate != null) {
      setState(() {
        _selectedExpiryDate = pickedDate;
      });
    }
  }

  void _saveItem() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    if (_selectedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an expiry date.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newItem = FoodItem(
      id: '',
      name: _nameController.text,
      category: _selectedCategory!,
      quantity: int.parse(_quantityController.text),
      unit: _selectedUnit,
      expiryDate: _selectedExpiryDate!,
      addedAt: DateTime.now(),
      brand: _brandController.text.isNotEmpty ? _brandController.text : null,
      storageLocation: _locationController.text.isNotEmpty ? _locationController.text : null,
      barcode: widget.scannedBarcode,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
    );

    ref.read(foodServiceProvider).addFoodItem(newItem);

    // Notification Logic
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 1. Test Notification (10 seconds)
    final testDate = DateTime.now().add(const Duration(seconds: 10));
    NotificationService().scheduleNotification(
      id: notificationId + 999,
      title: 'Test: ${newItem.name}',
      body: 'This is how your reminder will look!',
      scheduledDate: testDate,
    );

    // 2. Real Notifications
    final reminderDate = _selectedExpiryDate!.subtract(const Duration(days: 3));
    final reminderAt9AM = DateTime(
      reminderDate.year, reminderDate.month, reminderDate.day, 9, 0, 0
    );

    if (reminderAt9AM.isAfter(DateTime.now())) {
      NotificationService().scheduleNotification(
        id: notificationId,
        title: 'Expiring Soon!',
        body: '${newItem.name} expires in 3 days.',
        scheduledDate: reminderAt9AM,
      );
    }

    final expiryAt9AM = DateTime(
      _selectedExpiryDate!.year, _selectedExpiryDate!.month, _selectedExpiryDate!.day, 9, 0, 0
    );

    if (expiryAt9AM.isAfter(DateTime.now())) {
      NotificationService().scheduleNotification(
        id: notificationId + 1,
        title: 'Item Expired',
        body: '${newItem.name} has expired today.',
        scheduledDate: expiryAt9AM,
      );
    }

    NotificationService().showNotification(
      title: 'Item Added',
      body: 'Reminder set for ${DateFormat.Md().format(_selectedExpiryDate!)}',
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  InputDecoration _modernInput(String label, IconData icon, BuildContext context) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            widget.scannedItemName != null ? 'Confirm Item' : 'New Item',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saveItem,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 4,
          icon: const Icon(PhosphorIconsDuotone.floppyDisk),
          label: const Text("Save Item", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Section
                TextFormField(
                  controller: _nameController,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400),
                  decoration: _modernInput('What is it?', PhosphorIconsDuotone.package, context).copyWith(
                    hintText: 'e.g. Apple',
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
      
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Select Category'),
                  decoration: _modernInput('Category', PhosphorIconsDuotone.tag, context),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
      
                // --- 2. UPDATED QUANTITY ROW WITH +/- BUTTONS ---
                Row(
                  children: [
                    // Quantity Stepper
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Minus Button
                            IconButton(
                              onPressed: () => _updateQuantity(-1),
                              icon: Icon(PhosphorIconsDuotone.minus, size: 20),
                              color: theme.colorScheme.primary,
                            ),
                            // Text Field
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  isDense: true,
                                ),
                                validator: (val) => (val == null || val.isEmpty) ? 'Req' : null,
                              ),
                            ),
                            // Plus Button
                            IconButton(
                              onPressed: () => _updateQuantity(1),
                              icon: Icon(PhosphorIconsDuotone.plus, size: 20),
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Unit Dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: _modernInput('Unit', PhosphorIconsDuotone.ruler, context),
                        items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setState(() => _selectedUnit = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
      
                // 3. Hero Date Picker
                Text("Expiry Date", style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _presentDatePicker,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _selectedExpiryDate == null 
                          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedExpiryDate == null 
                            ? Colors.transparent 
                            : theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsDuotone.calendarCheck,
                          size: 28,
                          color: _selectedExpiryDate == null 
                              ? Colors.grey 
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedExpiryDate == null
                              ? 'Tap to set Expiry Date'
                              : DateFormat.yMMMMd().format(_selectedExpiryDate!),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _selectedExpiryDate == null 
                                ? Colors.grey 
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
      
                // 4. Optional Details
                Text(
                  'More Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
      
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _modernInput('Notes', PhosphorIconsDuotone.note, context).copyWith(
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
      
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: _modernInput('Brand', PhosphorIconsDuotone.tagChevron, context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: _modernInput('Location', PhosphorIconsDuotone.package, context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}