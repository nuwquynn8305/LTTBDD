import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/transaction.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';

class RecentTransactionsWidget extends ConsumerWidget {
  final VoidCallback? onViewAll;

  const RecentTransactionsWidget({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
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
                  strings.noRecentTransactions,
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
                      strings.recentTransactions,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(strings.viewAll),
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
          Center(child: Text(strings.errorLoading('$error'))),
    );
  }
}

class TransactionTile extends ConsumerWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? colorScheme.tertiary : colorScheme.error;
    final categoryColor = Categories.getMaterialColor(transaction.category);
    final localizedCategory =
        Categories.getLocalizedName(transaction.category, locale.languageCode);

    final dateFormat = locale.languageCode == 'vi'
        ? DateFormat('dd/MM/yyyy', 'vi_VN')
        : DateFormat('MMM dd, yyyy', 'en_US');

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
            title: Text(strings.deleteTransactionConfirmTitle),
            content: Text(strings.deleteTransactionConfirmMsg),
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
            '${dateFormat.format(transaction.date)} • $localizedCategory',
          ),
          trailing: Text(
            currency.formatWithSign(transaction.amount, isIncome: isIncome),
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
