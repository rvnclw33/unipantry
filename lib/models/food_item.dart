import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String unit; // NEW: e.g., 'pcs', 'kg', 'g', 'L'
  final String? storageLocation;
  final DateTime expiryDate;
  final DateTime addedAt;
  final String? brand;
  final String? barcode;
  final String? description; // NEW: For extra info or manual notes

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    this.unit = 'pcs', // Default to pieces
    this.storageLocation,
    required this.expiryDate,
    required this.addedAt,
    this.brand,
    this.barcode,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit, // NEW
      'storageLocation': storageLocation,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'addedAt': Timestamp.fromDate(addedAt),
      'brand': brand,
      'barcode': barcode,
      'description': description, // NEW
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json, String id) {
    return FoodItem(
      id: id,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String? ?? 'pcs', // Handle old items safely
      storageLocation: json['storageLocation'] as String?,
      expiryDate: (json['expiryDate'] as Timestamp).toDate(),
      addedAt: (json['addedAt'] as Timestamp).toDate(),
      brand: json['brand'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?, // NEW
    );
  }
  
  // Helper to create a copy for editing
  FoodItem copyWith({
    String? name,
    String? category,
    int? quantity,
    String? unit,
    String? storageLocation,
    DateTime? expiryDate,
    String? brand,
    String? description,
  }) {
    return FoodItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      storageLocation: storageLocation ?? this.storageLocation,
      expiryDate: expiryDate ?? this.expiryDate,
      addedAt: addedAt,
      brand: brand ?? this.brand,
      barcode: barcode,
      description: description ?? this.description,
    );
  }
}