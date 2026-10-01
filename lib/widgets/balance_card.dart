import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/transaction_provider.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final currency = ref.watch(currencyNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return balanceAsync.when(
      data: (balance) {
        final incomeAsync = ref.watch(totalIncomeProvider);
        final expensesAsync = ref.watch(totalExpensesProvider);

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.currentBalance,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currency.format(balance),
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: incomeAsync.when(
                        data: (income) => _StatItem(
                          label: strings.totalIncome,
                          amount: income,
                          icon: Icons.north_east,
                          color: colorScheme.tertiary,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => Text(strings.errorGeneric),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: expensesAsync.when(
                        data: (expenses) => _StatItem(
                          label: strings.totalExpenses,
                          amount: expenses,
                          icon: Icons.south_west,
                          color: colorScheme.error,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => Text(strings.errorGeneric),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(strings.errorLoading('$error')),
        ),
      ),
    );
  }
}

class _StatItem extends ConsumerWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  currency.format(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
