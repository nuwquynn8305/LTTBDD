import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/transaction.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';
import '../widgets/empty_state.dart';
import '../widgets/theme_action_button.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.navTransactions),
          actions: const [ThemeActionButton()],
          bottom: TabBar(
            tabs: [
              Tab(text: strings.tabExpenses, icon: const Icon(Icons.south_west)),
              Tab(text: strings.tabIncome, icon: const Icon(Icons.north_east)),
            ],
          ),
        ),
        body: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: strings.noTransactions,
                message: strings.noTransactionsDesc,
                actionLabel: strings.addTransaction,
                onAction: () => _openEditor(context),
              );
            }

            final incomeTransactions =
                transactions.where((t) => t.type == 'income').toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

            final expenseTransactions =
                transactions.where((t) => t.type == 'expense').toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

            return TabBarView(
              children: [
                _TransactionList(transactions: expenseTransactions),
                _TransactionList(transactions: incomeTransactions),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text(strings.errorLoading('$error'))),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(context),
          icon: const Icon(Icons.add),
          label: Text(strings.addTransaction),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, {Transaction? transaction}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  final List<Transaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);

    if (transactions.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off_outlined,
        title: strings.noItemsInTab,
        message: strings.noItemsInTabDesc,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyNotifierProvider);

    final dateFormat = locale.languageCode == 'vi'
        ? DateFormat('dd/MM/yyyy HH:mm', 'vi_VN')
        : DateFormat('MMM dd, yyyy HH:mm', 'en_US');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isIncome = transaction.type == 'income';
        final amountColor = isIncome
            ? colorScheme.tertiary
            : colorScheme.error;
        final categoryColor = Categories.getMaterialColor(transaction.category);
        final localizedCategory =
            Categories.getLocalizedName(transaction.category, locale.languageCode);

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
          confirmDismiss: (direction) => _confirmDelete(context, strings),
          onDismissed: (direction) {
            ref
                .read(transactionNotifierProvider.notifier)
                .deleteTransaction(transaction.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.transactionDeleted)),
            );
          },
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: categoryColor.withValues(alpha: 0.16),
                foregroundColor: categoryColor,
                child: Icon(Categories.getMaterialIcon(transaction.category)),
              ),
              title: Text(
                transaction.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${dateFormat.format(transaction.date)}\n$localizedCategory',
              ),
              isThreeLine: true,
              trailing: Text(
                currency.formatWithSign(transaction.amount, isIncome: isIncome),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddTransactionScreen(transaction: transaction),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppStrings strings) async {
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
  }
}
