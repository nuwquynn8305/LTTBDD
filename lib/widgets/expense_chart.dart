import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';

class ExpenseChart extends ConsumerWidget {
  const ExpenseChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final expenseAsync = ref.watch(expenseByCategoryProvider(currentMonth));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ chi tiêu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: expenseAsync.when(
                data: (spending) {
                  if (spending.isEmpty || spending.values.every((v) => v == 0)) {
                    return const Center(
                      child: Text(
                        'Chưa có dữ liệu chi tiêu tháng này',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // Calculate total to show percentages
                  final total = spending.values.reduce((a, b) => a + b);
                  
                  // Filter out zero values and create sections
                  final validCategories = spending.entries.where((e) => e.value > 0).toList();
                  
                  // Sort by amount descending
                  validCategories.sort((a, b) => b.value.compareTo(a.value));

                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: validCategories.asMap().entries.map((entry) {
                              // final index = entry.key;
                              final data = entry.value;
                              final percentage = (data.value / total * 100);
                              
                              final colorList = Categories.getColor(data.key);
                              final color = Color.fromARGB(colorList[0], colorList[1], colorList[2], colorList[3]);
                              
                              return PieChartSectionData(
                                color: color,
                                value: data.value,
                                title: '${percentage.toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: validCategories.length,
                          itemBuilder: (context, index) {
                            final item = validCategories[index];
                            final colorList = Categories.getColor(item.key);
                            final color = Color.fromARGB(colorList[0], colorList[1], colorList[2], colorList[3]);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.key,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(child: Text('Lỗi khi tải biểu đồ')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
