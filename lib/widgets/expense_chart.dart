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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiêu theo danh mục', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: expenseAsync.when(
                data: (spending) {
                  if (spending.isEmpty ||
                      spending.values.every((v) => v == 0)) {
                    return Center(
                      child: Text(
                        'Chưa có dữ liệu chi tiêu tháng này',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final total = spending.values.reduce((a, b) => a + b);
                  final validCategories = spending.entries
                      .where((e) => e.value > 0)
                      .toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 44,
                            sections: validCategories.map((data) {
                              final percentage = data.value / total * 100;
                              final color = Categories.getMaterialColor(
                                data.key,
                              );
                              return PieChartSectionData(
                                color: color,
                                value: data.value,
                                title: '${percentage.toStringAsFixed(0)}%',
                                radius: 48,
                                titleStyle: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ListView.builder(
                          itemCount: validCategories.length,
                          itemBuilder: (context, index) {
                            final item = validCategories[index];
                            final color = Categories.getMaterialColor(item.key);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.key,
                                      style: textTheme.bodySmall,
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
                error: (error, stack) =>
                    const Center(child: Text('Lỗi khi tải biểu đồ')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
