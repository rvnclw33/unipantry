// lib/widgets/food_card.dart
import 'package:flutter/material.dart';
import 'package:unipantry/models/food_item.dart';

class FoodCard extends StatelessWidget {
  final FoodItem item;
  const FoodCard({super.key, required this.item});

  // This helper function determines the expiry color
  Color _getExpiryColor(BuildContext context) {
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) {
      return Colors.red.shade700; // Expired
    } else if (daysLeft <= 3) {
      return Colors.orange.shade700; // Expiring soon
    } else {
      return Colors.green.shade700; // Fresh
    }
  }

  // This helper function gets the text for the expiry
  String _getExpiryText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
    
    final daysLeft = expiryDay.difference(today).inDays;

    if (daysLeft < 0) {
      return 'Expired';
    } else if (daysLeft == 0) {
      return 'Expires Today';
    } else if (daysLeft == 1) {
      return 'Expires Tomorrow';
    } else {
      return 'Expires in $daysLeft days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getExpiryColor(context);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // The color indicator bar
          Container(
            width: 8,
            height: 100, // Match the card height
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          
          // The main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    item.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Expiry Text
                  Text(
                    _getExpiryText(),
                    style: textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Row for details (Category & Quantity)
                  Row(
                    children: [
                      // Category Chip
                      Chip(
                        label: Text(item.category),
                        labelStyle: const TextStyle(fontSize: 12),
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      ),
                      const SizedBox(width: 8),

                      // Quantity
                      Chip(
                        label: Text('Qty: ${item.quantity}'),
                        labelStyle: const TextStyle(fontSize: 12),
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Brand or Location (optional)
          if (item.brand != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                item.brand!,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}