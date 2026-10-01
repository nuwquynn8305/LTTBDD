import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Giao dịch'),
          actions: const [ThemeActionButton()],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Khoản chi', icon: Icon(Icons.south_west)),
              Tab(text: 'Khoản thu', icon: Icon(Icons.north_east)),
            ],
          ),
        ),
        body: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có giao dịch',
                message: 'Thêm giao dịch đầu tiên để bắt đầu theo dõi chi tiêu.',
                actionLabel: 'Thêm giao dịch',
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
          error: (error, stack) => Center(child: Text('Lỗi: $error')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm giao dịch'),
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
    if (transactions.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_list_off_outlined,
        title: 'Không có mục nào',
        message: 'Chưa có giao dịch trong tab này.',
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

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
          confirmDismiss: (direction) => _confirmDelete(context),
          onDismissed: (direction) {
            ref
                .read(transactionNotifierProvider.notifier)
                .deleteTransaction(transaction.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa giao dịch')),
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
                '${DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(transaction.date)}\n${transaction.category}',
              ),
              isThreeLine: true,
              trailing: Text(
                '${isIncome ? '+' : '-'}${currency.format(transaction.amount)}',
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

  Future<bool> _confirmDelete(BuildContext context) async {
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
  }
}
