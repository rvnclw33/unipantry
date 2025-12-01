import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; 
import 'package:unipantry/models/food_item.dart';
import 'package:unipantry/screens/item_detail_screen.dart';

class FoodCard extends StatelessWidget {
  final FoodItem item;
  const FoodCard({super.key, required this.item});

  // --- Helper: Icon Mapping ---
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruit': return PhosphorIconsDuotone.orangeSlice;
      case 'vegetable': return PhosphorIconsDuotone.carrot;
      case 'meat': return PhosphorIconsDuotone.cow;
      case 'seafood': return PhosphorIconsDuotone.fish;
      case 'dairy': return PhosphorIconsDuotone.cheese;
      case 'bakery': return PhosphorIconsDuotone.bread;
      case 'pantry': return PhosphorIconsDuotone.cookie;
      case 'drinks': return PhosphorIconsDuotone.brandy;
      default: return PhosphorIconsDuotone.bowlFood;
    }
  }

  Color _getExpiryColor(BuildContext context) {
    final daysLeft = item.expiryDate.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
    if (daysLeft < 0) return Colors.red.shade700;
    if (daysLeft <= 2) return Colors.redAccent;
    if (daysLeft <= 7) return Colors.orange.shade800;
    return Colors.green.shade600;
  }

  String _getExpiryText() {
    final daysLeft = item.expiryDate.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
    if (daysLeft < 0) return 'Expired';
    if (daysLeft == 0) return 'Expires Today';
    if (daysLeft == 1) return 'Expires Tomorrow';
    if (daysLeft <= 7) return 'Expires in $daysLeft days';
    return 'Expires ${item.expiryDate.month}/${item.expiryDate.day}';
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)));
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: theme.colorScheme.primary, size: 26),
                      ),
                      const SizedBox(width: 12),
                      
                      // --- FIX: Use Flexible for Text Column ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis, // Prevents overflow
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getExpiryText(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.quantity} ${item.unit}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          if (item.brand != null)
                            // Limit width of brand text
                            Container(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                item.brand!,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
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