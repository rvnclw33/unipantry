import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/providers/food_provider.dart';

// Create a provider for the waste log specifically
final wasteLogStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  final firestore = ref.watch(firestoreProvider);
  if (householdId == null) return Stream.value([]);

  return firestore.collection('households').doc(householdId).collection('waste_logs')
      .orderBy('wastedAt', descending: true)
      .limit(50) // Limit to last 50 items for performance
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());
});

class WasteScreen extends ConsumerWidget {
  const WasteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wasteListAsync = ref.watch(wasteLogStreamProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Waste Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: wasteListAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsDuotone.leaf, size: 80, color: Colors.green.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  const Text("No waste recorded!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text("Keep up the good work!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Calculation Logic
          final categoryCounts = <String, int>{};
          for (var item in items) {
            final cat = item['category'] ?? 'Other';
            categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
          }
          final mostWasted = categoryCounts.entries.isEmpty 
              ? '-' 
              : categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. HERO STATS ---
                Row(
                  children: [
                    Expanded(
                      child: _buildModernStatCard(
                        context, 
                        'Total Wasted', 
                        '${items.length}', 
                        PhosphorIconsDuotone.trash, 
                        Colors.red.shade50, 
                        Colors.red.shade700
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernStatCard(
                        context, 
                        'Top Category', 
                        mostWasted, 
                        PhosphorIconsDuotone.chartBar, 
                        Colors.orange.shade50, 
                        Colors.orange.shade800
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // --- 2. DONUT CHART ---
                Text("Waste Breakdown", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: categoryCounts.entries.map((entry) {
                            return PieChartSectionData(
                              color: _getCategoryColor(entry.key),
                              value: entry.value.toDouble(),
                              title: '', // No text inside slice
                              radius: 25, // Thinner ring
                              showTitle: false,
                            );
                          }).toList(),
                          centerSpaceRadius: 60, // Donut hole
                          sectionsSpace: 4,
                        ),
                      ),
                      // Text in the middle of donut
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${items.length}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text("Items", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Legend
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: categoryCounts.keys.map((cat) => Chip(
                    avatar: CircleAvatar(backgroundColor: _getCategoryColor(cat), radius: 4),
                    label: Text(cat),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),

                const SizedBox(height: 32),
                
                // --- 3. RECENT HISTORY ---
                Text("Recent Log", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final catColor = _getCategoryColor(item['category'] ?? 'Other');
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(PhosphorIconsDuotone.trash, size: 20, color: catColor),
                        ),
                        title: Text(
                          item['name'] ?? 'Unknown', 
                          style: const TextStyle(fontWeight: FontWeight.w600)
                        ),
                        subtitle: Text(
                          item['wastedAt'] != null 
                              ? (item['wastedAt'] as Timestamp).toDate().toString().split(' ')[0] 
                              : '',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        trailing: Text(
                          "-${item['quantity']} ${item['unit']}", 
                          style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildModernStatCard(BuildContext context, String title, String value, IconData icon, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: text),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: text, height: 1.0)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text.withOpacity(0.7))),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Fruit': return Colors.redAccent;
      case 'Vegetable': return Colors.green;
      case 'Meat': return Colors.brown;
      case 'Dairy': return Colors.blue;
      case 'Bakery': return Colors.orange;
      case 'Drinks': return Colors.purple;
      default: return Colors.grey;
    }
  }
}