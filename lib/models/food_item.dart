// lib/models/food_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final String category; // NEW
  final int quantity; // NEW
  final String? storageLocation; // NEW (Optional)
  final DateTime expiryDate;
  final DateTime addedAt;
  final String? brand; // NEW (Optional)
  final String? barcode; // NEW (Optional)

  FoodItem({
    required this.id,
    required this.name,
    required this.category, // NEW
    required this.quantity, // NEW
    this.storageLocation, // NEW
    required this.expiryDate,
    required this.addedAt,
    this.brand, // NEW
    this.barcode, // NEW
  });

  // Convert a FoodItem object into a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category, // NEW
      'quantity': quantity, // NEW
      'storageLocation': storageLocation, // NEW
      'expiryDate': Timestamp.fromDate(expiryDate),
      'addedAt': Timestamp.fromDate(addedAt),
      'brand': brand, // NEW
      'barcode': barcode, // NEW
    };
  }

  // Create a FoodItem object from a Firestore document
  factory FoodItem.fromJson(Map<String, dynamic> json, String id) {
    return FoodItem(
      id: id,
      name: json['name'] as String,
      category: json['category'] as String, // NEW
      quantity: json['quantity'] as int, // NEW
      storageLocation: json['storageLocation'] as String?, // NEW
      expiryDate: (json['expiryDate'] as Timestamp).toDate(),
      addedAt: (json['addedAt'] as Timestamp).toDate(),
      brand: json['brand'] as String?, // NEW
      barcode: json['barcode'] as String?, // NEW
    );
  }
}