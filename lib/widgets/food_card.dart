import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; 
import 'package:unipantry/models/food_item.dart';
import 'package:unipantry/screens/item_detail_screen.dart';

class FoodCard extends StatelessWidget {
  final FoodItem item;
  const FoodCard({super.key, required this.item});

  // --- 1. Modern Icon Mapping (Phosphor Duotone) ---
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruit': 
        return PhosphorIconsDuotone.orangeSlice; 
      case 'vegetable': 
        return PhosphorIconsDuotone.carrot;
      case 'meat': 
        return PhosphorIconsDuotone.cow; 
      case 'seafood':
        return PhosphorIconsDuotone.fish;  
      case 'dairy': 
        return PhosphorIconsDuotone.cheese;
      case 'bakery': 
        return PhosphorIconsDuotone.bread;
      case 'snacks': 
        return PhosphorIconsDuotone.cookie; 
      case 'drinks': 
        return PhosphorIconsDuotone.brandy; 
      case 'other':
      default: 
        return PhosphorIconsDuotone.bowlFood;
    }
  }

  // --- 2. IMPROVED COLOR LOGIC ---
  Color _getExpiryColor(BuildContext context) {
    final now = DateTime.now();
    // Strip time to compare only dates (Midnight to Midnight)
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
    
    final daysLeft = expiryDay.difference(today).inDays;

    // A. EXPIRED (In the past)
    if (daysLeft < 0) {
      return const Color.fromARGB(255, 193, 0, 0); 
    } 
    
    // B. URGENT (Today, Tomorrow, Day After)
    else if (daysLeft <= 2) {
      return const Color.fromARGB(255, 217, 126, 0); 
    } 
    
    // C. WARNING (Expires within 1 week)
    // This helps separate "Soon" from "Fresh"
    else if (daysLeft <= 7) {
      return const Color.fromARGB(255, 88, 229, 0); 
    } 
    
    // D. FRESH (More than 1 week)
    else {
      // Standard green is much more visible than the previous dark green
      return const Color.fromARGB(255, 35, 123, 40); 
    }
  }

  // --- Helper: Text Description ---
  String _getExpiryText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
    final daysLeft = expiryDay.difference(today).inDays;

    if (daysLeft < 0) return 'Expired';
    if (daysLeft == 0) return 'Expires Today';
    if (daysLeft == 1) return 'Expires Tomorrow';
    if (daysLeft <= 7) return 'Expires in $daysLeft days';
    
    // For items far in the future, show actual date
    return 'Expires ${expiryDay.month}/${expiryDay.day}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getExpiryColor(context);
    final icon = _getCategoryIcon(item.category);
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Color Strip
              Container(width: 6, color: color),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Category Icon Box
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: theme.colorScheme.primary, size: 26),
                      ),
                      const SizedBox(width: 12),

                      // Main Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getExpiryText(),
                              style: TextStyle(
                                color: color, // Text matches the status color
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity + Unit
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.quantity} ${item.unit}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (item.brand != null)
                             Text(
                              item.brand!,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}