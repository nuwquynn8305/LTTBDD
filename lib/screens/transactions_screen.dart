import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/categories.dart';
import '../widgets/empty_state.dart';
import '../widgets/theme_action_button.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final selectedFilterId = ref.watch(selectedWalletFilterProvider);
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.navTransactions),
          actions: const [ThemeActionButton()],
          bottom: TabBar(
            tabs: [
              Tab(text: strings.tabExpenses, icon: const Icon(Icons.south_west)),
              Tab(text: strings.tabIncome, icon: const Icon(Icons.north_east)),
              Tab(text: strings.tabTransfer, icon: const Icon(Icons.sync_alt)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Wallet filter horizontal chips
            walletsAsync.when(
              data: (wallets) {
                if (wallets.isEmpty) return const SizedBox.shrink();
                return Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: selectedFilterId == null,
                          label: Text(strings.allWallets),
                          onSelected: (_) {
                            ref
                                .read(selectedWalletFilterProvider.notifier)
                                .state = null;
                          },
                        ),
                      ),
                      ...wallets.map((w) {
                        final isSelected = selectedFilterId == w.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: Icon(w.iconData, size: 16, color: w.color),
                            selected: isSelected,
                            label: Text(w.name),
                            onSelected: (_) {
                              ref
                                  .read(selectedWalletFilterProvider.notifier)
                                  .state = isSelected ? null : w.id;
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  final filtered = selectedFilterId == null
                      ? transactions
                      : transactions
                          .where(
                            (t) =>
                                t.walletId == selectedFilterId ||
                                t.toWalletId == selectedFilterId,
                          )
                          .toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: strings.noTransactions,
                      message: strings.noTransactionsDesc,
                      actionLabel: strings.addTransaction,
                      onAction: () => _openEditor(context),
                    );
                  }

                  final incomeTransactions = filtered
                      .where((t) => t.type == 'income')
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  final expenseTransactions = filtered
                      .where((t) => t.type == 'expense')
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  final transferTransactions = filtered
                      .where((t) => t.type == 'transfer')
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return TabBarView(
                    children: [
                      _TransactionList(transactions: expenseTransactions),
                      _TransactionList(transactions: incomeTransactions),
                      _TransactionList(transactions: transferTransactions),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text(strings.errorLoading('$error'))),
              ),
            ),
          ],
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
    final walletsAsync = ref.watch(walletsProvider);
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

    final walletsMap = <String, Wallet>{};
    walletsAsync.whenData((wallets) {
      for (var w in wallets) {
        walletsMap[w.id] = w;
      }
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isIncome = transaction.type == 'income';
        final isTransfer = transaction.type == 'transfer';

        final amountColor = isTransfer
            ? colorScheme.primary
            : (isIncome ? colorScheme.tertiary : colorScheme.error);

        final categoryColor = isTransfer
            ? colorScheme.primary
            : Categories.getMaterialColor(transaction.category);

        final localizedCategory = isTransfer
            ? strings.transfer
            : Categories.getLocalizedName(
                transaction.category,
                locale.languageCode,
              );

        final fromWallet = walletsMap[transaction.walletId];
        final toWallet = walletsMap[transaction.toWalletId];

        String subtitleText =
            '${dateFormat.format(transaction.date)} • $localizedCategory';

        if (isTransfer && fromWallet != null && toWallet != null) {
          subtitleText += '\n${fromWallet.name} ➔ ${toWallet.name}';
        } else if (fromWallet != null) {
          subtitleText += ' (${fromWallet.name})';
        }

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
                child: Icon(
                  isTransfer
                      ? Icons.sync_alt
                      : Categories.getMaterialIcon(transaction.category),
                ),
              ),
              title: Text(
                transaction.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(subtitleText),
              isThreeLine: isTransfer || fromWallet != null,
              trailing: Text(
                isTransfer
                    ? currency.format(transaction.amount)
                    : currency.formatWithSign(
                        transaction.amount,
                        isIncome: isIncome,
                      ),
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
