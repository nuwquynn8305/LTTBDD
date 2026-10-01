import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
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
    final locale = ref.watch(localeNotifierProvider);
    final currency = ref.watch(currencyNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final monthFormat = locale.languageCode == 'vi'
        ? DateFormat('MMMM yyyy', 'vi_VN')
        : DateFormat('MMMM yyyy', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.navBudgets),
        actions: const [ThemeActionButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              monthFormat.format(now),
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
                    title: strings.noBudgets,
                    message: strings.noBudgetsDesc,
                    actionLabel: strings.addBudget,
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
                            final localizedCategory =
                                Categories.getLocalizedName(
                                  budget.category,
                                  locale.languageCode,
                                );
                            final progressColor = isOverBudget
                                ? colorScheme.error
                                : colorScheme.primary;

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () =>
                                    _openEditor(context, budget: budget),
                                onLongPress: () =>
                                    _confirmDelete(context, ref, budget.id, strings),
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
                                              localizedCategory,
                                              style: textTheme.titleMedium,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: strings.editTooltip,
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
                                            ? '${strings.overBudget} ${currency.format(spent - budget.limit)}'
                                            : '${strings.remaining} ${currency.format(remaining)}',
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
                          child: Text(strings.errorLoadingStatus('$error')),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(strings.errorLoadingExpense('$error')),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(strings.errorLoading('$error')),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(strings.addBudget),
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
    AppStrings strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(strings.deleteBudgetConfirmTitle),
        content: Text(strings.deleteBudgetConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(budgetNotifierProvider.notifier).deleteBudget(budgetId);
    }
  }
}
