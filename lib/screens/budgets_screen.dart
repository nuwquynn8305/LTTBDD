import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';
import '../widgets/empty_state.dart';
import '../widgets/theme_action_button.dart';
import 'add_budget_screen.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final budgetsAsync = ref.watch(budgetsByMonthProvider);
    final spendingAsync = ref.watch(expenseByCategoryProvider(currentMonth));
    final budgetStatusAsync = ref.watch(budgetStatusProvider(currentMonth));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân sách'),
        actions: const [ThemeActionButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              DateFormat('MMMM yyyy', 'vi_VN').format(now),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Chưa có ngân sách',
                    message:
                        'Đặt hạn mức theo danh mục để theo dõi chi tiêu tháng này.',
                    actionLabel: 'Thêm ngân sách',
                    onAction: () => _openEditor(context),
                  );
                }

                return spendingAsync.when(
                  data: (spending) {
                    return budgetStatusAsync.when(
                      data: (status) {
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                          itemCount: budgets.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final budget = budgets[index];
                            final spent = spending[budget.category] ?? 0;
                            final remaining =
                                status[budget.category] ?? budget.limit;
                            final percentage = (spent / budget.limit).clamp(
                              0.0,
                              1.0,
                            );
                            final isOverBudget = spent > budget.limit;
                            final categoryColor = Categories.getMaterialColor(
                              budget.category,
                            );
                            final progressColor = isOverBudget
                                ? colorScheme.error
                                : colorScheme.primary;
                            final currency = NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: '₫',
                              decimalDigits: 0,
                            );

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () =>
                                    _openEditor(context, budget: budget),
                                onLongPress: () =>
                                    _confirmDelete(context, ref, budget.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: categoryColor
                                                .withValues(alpha: 0.16),
                                            foregroundColor: categoryColor,
                                            child: Icon(
                                              Categories.getMaterialIcon(
                                                budget.category,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              budget.category,
                                              style: textTheme.titleMedium,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Chỉnh sửa',
                                            icon: const Icon(Icons.edit_outlined),
                                            onPressed: () => _openEditor(
                                              context,
                                              budget: budget,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage,
                                          minHeight: 8,
                                          color: progressColor,
                                          backgroundColor:
                                              colorScheme.surfaceContainerHighest,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${currency.format(spent)} / ${currency.format(budget.limit)}',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: isOverBudget
                                              ? colorScheme.error
                                              : colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isOverBudget
                                            ? 'Vượt ${currency.format(spent - budget.limit)}'
                                            : 'Còn lại ${currency.format(remaining)}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: isOverBudget
                                              ? colorScheme.error
                                              : colorScheme.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Lỗi khi tải trạng thái: $error'),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Lỗi khi tải chi tiêu: $error'),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ngân sách'),
      ),
    );
  }

  void _openEditor(BuildContext context, {Budget? budget}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddBudgetScreen(budget: budget)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String budgetId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Xóa ngân sách?'),
        content: const Text(
          'Ngân sách này sẽ bị xóa khỏi tháng hiện tại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(budgetNotifierProvider.notifier).deleteBudget(budgetId);
    }
  }
}
