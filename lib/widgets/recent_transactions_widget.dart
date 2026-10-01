import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';

class RecentTransactionsWidget extends ConsumerWidget {
  final VoidCallback? onViewAll;

  const RecentTransactionsWidget({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return recentTransactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Chưa có giao dịch nào',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Giao dịch gần đây',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: transactions.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return TransactionTile(transaction: transactions[index]);
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) =>
          const Center(child: Text('Lỗi khi tải giao dịch')),
    );
  }
}

class TransactionTile extends ConsumerWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? colorScheme.tertiary : colorScheme.error;
    final categoryColor = Categories.getMaterialColor(transaction.category);
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.delete_outline),
            title: const Text('Xóa giao dịch?'),
            content: const Text(
              'Giao dịch này sẽ bị xóa khỏi thiết bị của bạn.',
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
        return confirmed ?? false;
      },
      onDismissed: (direction) {
        ref
            .read(transactionNotifierProvider.notifier)
            .deleteTransaction(transaction.id);
      },
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: categoryColor.withValues(alpha: 0.16),
            foregroundColor: categoryColor,
            child: Icon(Categories.getMaterialIcon(transaction.category)),
          ),
          title: Text(transaction.title),
          subtitle: Text(
            DateFormat('dd/MM/yyyy', 'vi_VN').format(transaction.date),
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}${currency.format(transaction.amount)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ),
      ),
    );
  }
}
