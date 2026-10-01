import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

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
                  'Số dư hiện tại',
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
                          label: 'Thu nhập',
                          amount: income,
                          icon: Icons.north_east,
                          color: colorScheme.tertiary,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Lỗi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: expensesAsync.when(
                        data: (expenses) => _StatItem(
                          label: 'Chi tiêu',
                          amount: expenses,
                          icon: Icons.south_west,
                          color: colorScheme.error,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Lỗi'),
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
          child: Text('Lỗi: $error'),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

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
