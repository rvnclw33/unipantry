import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Need this for weekday names
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/providers/food_provider.dart';

final wasteLogStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  final firestore = ref.watch(firestoreProvider);
  if (householdId == null) return Stream.value([]);

  return firestore
      .collection('households')
      .doc(householdId)
      .collection('waste_logs')
      .orderBy('wastedAt', descending: true)
      .limit(100) 
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());
});

enum WasteFilter { week, month, year, all }

class WasteScreen extends ConsumerStatefulWidget {
  const WasteScreen({super.key});

  @override
  ConsumerState<WasteScreen> createState() => _WasteScreenState();
}

class _WasteScreenState extends ConsumerState<WasteScreen> {
  WasteFilter _selectedFilter = WasteFilter.month;

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> allItems) {
    final now = DateTime.now();
    return allItems.where((item) {
      final Timestamp? ts = item['wastedAt'];
      if (ts == null) return false;
      final date = ts.toDate();

      switch (_selectedFilter) {
        case WasteFilter.week: return date.isAfter(now.subtract(const Duration(days: 7)));
        case WasteFilter.month: return date.isAfter(now.subtract(const Duration(days: 30)));
        case WasteFilter.year: return date.isAfter(now.subtract(const Duration(days: 365)));
        default: return true;
      }
    }).toList();
  }

  // --- Prepare Data for Bar Chart (Last 7 Days) ---
  Map<int, int> _getWeeklyData(List<Map<String, dynamic>> items) {
    // 0 = Today, 1 = Yesterday... 6 = 6 days ago
    Map<int, int> days = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0, 6:0};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (var item in items) {
      final Timestamp? ts = item['wastedAt'];
      if (ts == null) continue;
      final date = ts.toDate();
      
      // Difference in days
      final diff = todayStart.difference(DateTime(date.year, date.month, date.day)).inDays;
      if (diff >= 0 && diff <= 6) {
        days[6 - diff] = (days[6 - diff] ?? 0) + 1; // Reverse order for chart (Left=Oldest)
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
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
        data: (allItems) {
          final filteredItems = _filterItems(allItems);
          
          // Stats Calculation
          final categoryCounts = <String, int>{};
          for (var item in filteredItems) {
            final cat = item['category'] ?? 'Other';
            categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
          }
          final mostWasted = categoryCounts.entries.isEmpty 
              ? '-' 
              : categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          final weeklyData = _getWeeklyData(allItems);
          // Calculate max Y value for chart scaling
          final maxY = (weeklyData.values.fold<int>(0, (p, c) => p > c ? p : c) + 2).toDouble();

          if (allItems.isEmpty) {
             return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. TREND CHART (Redesigned) ---
                Text("Last 7 Days Trend", style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey)),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, // Clean background
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: theme.colorScheme.inverseSurface,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              rod.toY.round().toString(),
                              TextStyle(
                                color: theme.colorScheme.onInverseSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade100,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              // Calculate day name (e.g., "Mon")
                              final dayIndex = value.toInt();
                              final date = DateTime.now().subtract(Duration(days: 6 - dayIndex));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat.E().format(date), // 3-letter day name
                                  style: TextStyle(
                                    color: Colors.grey.shade600, 
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: weeklyData.entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              // Use Gradient for a modern look
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.3),
                                  theme.colorScheme.primary,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // --- 2. BENTO GRID STATS ---
                Row(
                  children: [
                    Expanded(
                      child: _buildModernStatCard(
                        context, 
                        'Total Items', 
                        '${filteredItems.length}', 
                        PhosphorIconsDuotone.trash, 
                        Colors.red.shade50, 
                        Colors.red.shade700
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernStatCard(
                        context, 
                        'Worst Category', 
                        mostWasted, 
                        PhosphorIconsDuotone.warning, 
                        Colors.orange.shade50, 
                        Colors.orange.shade800
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // --- 3. CATEGORY BREAKDOWN ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Composition", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    DropdownButton<WasteFilter>(
                      value: _selectedFilter,
                      items: const [
                        DropdownMenuItem(value: WasteFilter.week, child: Text("This Week")),
                        DropdownMenuItem(value: WasteFilter.month, child: Text("This Month")),
                        DropdownMenuItem(value: WasteFilter.year, child: Text("This Year")),
                        DropdownMenuItem(value: WasteFilter.all, child: Text("All Time")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedFilter = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Donut Chart
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: categoryCounts.entries.map((entry) {
                        return PieChartSectionData(
                          color: _getCategoryColor(entry.key),
                          value: entry.value.toDouble(),
                          title: '${entry.value}', // Number inside slice
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          radius: 30,
                          showTitle: true,
                        );
                      }).toList(),
                      centerSpaceRadius: 50,
                      sectionsSpace: 4,
                    ),
                  ),
                ),
                
                // Legend Grid
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryCounts.keys.map((cat) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(backgroundColor: _getCategoryColor(cat), radius: 4),
                        const SizedBox(width: 8),
                        Text(cat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )).toList(),
                ),
                
                const SizedBox(height: 32),
                
                // --- 4. RECENT LOG ---
                Text("History Log", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final catColor = _getCategoryColor(item['category'] ?? 'Other');
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 2))
                        ]
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(PhosphorIconsDuotone.trash, size: 20, color: catColor),
                        ),
                        title: Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          item['wastedAt'] != null 
                             ? DateFormat.yMMMd().format((item['wastedAt'] as Timestamp).toDate()) 
                             : '',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        trailing: Text(
                          "-${item['quantity']}", 
                          style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 16)
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: text),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: text, height: 1.0)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsDuotone.smiley, size: 80, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text("No Waste Recorded!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          const Text("Your pantry is perfectly efficient.", style: TextStyle(color: Colors.grey)),
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
      case 'Bakery': return Colors.amber;
      case 'Drinks': return Colors.purple;
      default: return Colors.grey;
    }
  }
}