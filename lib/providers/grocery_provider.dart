import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipantry/models/food_item.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/providers/food_provider.dart';

// --- 1. SMART DICTIONARY ---
const Map<String, String> _groceryDictionary = {
  'Apple': 'Fruit', 'Banana': 'Fruit', 'Orange': 'Fruit', 'Grapes': 'Fruit', 'Lemon': 'Fruit',
  'Carrot': 'Vegetable', 'Broccoli': 'Vegetable', 'Onion': 'Vegetable', 'Potato': 'Vegetable', 'Tomato': 'Vegetable', 'Garlic': 'Vegetable',
  'Milk': 'Dairy', 'Cheese': 'Dairy', 'Butter': 'Dairy', 'Yogurt': 'Dairy', 'Cream': 'Dairy', 'Eggs': 'Dairy',
  'Chicken': 'Meat', 'Beef': 'Meat', 'Pork': 'Meat', 'Fish': 'Meat', 'Bacon': 'Meat',
  'Bread': 'Bakery', 'Bagel': 'Bakery', 'Croissant': 'Bakery', 'Tortilla': 'Bakery',
  'Rice': 'Pantry', 'Pasta': 'Pantry', 'Cereal': 'Pantry', 'Flour': 'Pantry', 'Sugar': 'Pantry', 'Oil': 'Pantry',
  'Water': 'Drinks', 'Juice': 'Drinks', 'Soda': 'Drinks', 'Coffee': 'Drinks', 'Tea': 'Drinks',
  'Shampoo': 'Household', 'Soap': 'Household', 'Toilet Paper': 'Household',
};

// --- 2. DATA MODEL ---
class GroceryItem {
  final String id;
  final String name;
  final String category;
  final bool isChecked;

  GroceryItem({
    required this.id, 
    required this.name, 
    this.category = 'Other',
    this.isChecked = false
  });

  Map<String, dynamic> toJson() => {
    'name': name, 
    'category': category,
    'isChecked': isChecked
  };

  factory GroceryItem.fromJson(Map<String, dynamic> json, String id) {
    return GroceryItem(
      id: id,
      name: json['name'] ?? '',
      category: json['category'] ?? 'Other',
      isChecked: json['isChecked'] ?? false,
    );
  }
}

final groceryStreamProvider = StreamProvider<List<GroceryItem>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  final firestore = ref.watch(firestoreProvider);

  if (householdId == null) return Stream.value([]);

  return firestore
      .collection('households')
      .doc(householdId)
      .collection('grocery_list')
      .orderBy('isChecked')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => GroceryItem.fromJson(doc.data(), doc.id))
          .toList());
});

final groceryActionsProvider = Provider((ref) {
  return GroceryActions(
    ref.watch(firestoreProvider),
    ref.watch(householdIdProvider),
  );
});

// --- 3. LOGIC CLASS ---
class GroceryActions {
  final FirebaseFirestore firestore;
  final String? householdId;

  GroceryActions(this.firestore, this.householdId);

  List<String> getSuggestions(String query) {
    if (query.isEmpty) return [];
    return _groceryDictionary.keys
        .where((key) => key.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> addItem(String name) async {
    if (householdId == null) return;
    
    String category = 'Other';
    final matchEntry = _groceryDictionary.entries.firstWhere(
      (entry) => entry.key.toLowerCase() == name.toLowerCase(),
      orElse: () => const MapEntry('', 'Other'),
    );
    
    if (matchEntry.key.isNotEmpty) {
      category = matchEntry.value;
      name = matchEntry.key; 
    } else if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }

    await firestore
        .collection('households')
        .doc(householdId)
        .collection('grocery_list')
        .add({
          'name': name, 
          'category': category, 
          'isChecked': false
        });
  }

  Future<void> toggleItem(String id, bool currentStatus) async {
    if (householdId == null) return;
    await firestore
        .collection('households')
        .doc(householdId)
        .collection('grocery_list')
        .doc(id)
        .update({'isChecked': !currentStatus});
  }

  // --- NEW: Delete Single Item ---
  Future<void> deleteItem(String id) async {
    if (householdId == null) return;
    await firestore
        .collection('households')
        .doc(householdId)
        .collection('grocery_list')
        .doc(id)
        .delete();
  }

  // --- Checkout (Move to Pantry) ---
  Future<int> checkoutCompletedItems() async {
    if (householdId == null) return 0;

    final batch = firestore.batch();
    final checkedItemsSnapshot = await firestore
        .collection('households')
        .doc(householdId)
        .collection('grocery_list')
        .where('isChecked', isEqualTo: true)
        .get();

    if (checkedItemsSnapshot.docs.isEmpty) return 0;

    int count = 0;
    final now = DateTime.now();
    final defaultExpiry = now.add(const Duration(days: 7)); 

    for (var doc in checkedItemsSnapshot.docs) {
      final data = doc.data();
      final item = GroceryItem.fromJson(data, doc.id);

      final newPantryRef = firestore
          .collection('households')
          .doc(householdId)
          .collection('items')
          .doc();

      final newFoodItem = FoodItem(
        id: newPantryRef.id,
        name: item.name,
        category: item.category,
        quantity: 1,
        unit: 'pcs',
        expiryDate: defaultExpiry, 
        addedAt: now,
        description: 'Bought via Grocery List',
      );

      batch.set(newPantryRef, newFoodItem.toJson());
      batch.delete(doc.reference);
      count++;
    }

    await batch.commit();
    return count;
  }

  // --- Delete Completed (No Pantry) ---
  Future<void> deleteCompleted() async {
    if (householdId == null) return;
    
    final completed = await firestore
        .collection('households')
        .doc(householdId)
        .collection('grocery_list')
        .where('isChecked', isEqualTo: true)
        .get();
    
    final batch = firestore.batch();
    for (var doc in completed.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}