import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/wallet.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/empty_state.dart';
import 'add_wallet_screen.dart';
import 'transfer_screen.dart';

class WalletsScreen extends ConsumerWidget {
  final String? initialWalletId;

  const WalletsScreen({super.key, this.initialWalletId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final totalNetWorthAsync = ref.watch(totalNetWorthProvider);
    final locale = ref.watch(localeNotifierProvider);
    final currency = ref.watch(currencyNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.myWallets),
        actions: [
          IconButton(
            tooltip: strings.transferBetweenWallets,
            icon: const Icon(Icons.sync_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransferScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Net Worth Banner
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    child: const Icon(Icons.account_balance),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.totalNetWorth,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        totalNetWorthAsync.when(
                          data: (total) => Text(
                            currency.format(total),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 20,
                            width: 80,
                            child: LinearProgressIndicator(),
                          ),
                          error: (_, __) => Text(strings.errorGeneric),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: walletsAsync.when(
              data: (wallets) {
                if (wallets.isEmpty) {
                  return EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Chưa có ví',
                    message: 'Thêm ví hoặc tài khoản đầu tiên để quản lý dòng tiền.',
                    actionLabel: strings.addWallet,
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddWalletScreen(),
                        ),
                      );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
                    return _WalletDetailCard(
                      wallet: wallet,
                      strings: strings,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(strings.errorLoading('$err'))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWalletScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(strings.addWallet),
      ),
    );
  }
}

class _WalletDetailCard extends ConsumerWidget {
  final Wallet wallet;
  final AppStrings strings;

  const _WalletDetailCard({
    required this.wallet,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));
    final currency = ref.watch(currencyNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: wallet.color.withValues(alpha: 0.18),
          foregroundColor: wallet.color,
          child: Icon(wallet.iconData),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                wallet.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (wallet.isDefault)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  strings.defaultBadge,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.getWalletTypeName(wallet.type),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            balanceAsync.when(
              data: (bal) => Text(
                currency.format(bal),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: bal < 0 ? colorScheme.error : colorScheme.primary,
                ),
              ),
              loading: () => const SizedBox(
                height: 14,
                width: 60,
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => Text(strings.errorGeneric),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.sync_alt, size: 16),
                  label: Text(strings.transfer),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransferScreen(initialFromWalletId: wallet.id),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: strings.editWallet,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddWalletScreen(wallet: wallet),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Xóa ví',
                  icon: const Icon(Icons.delete_outline),
                  color: colorScheme.error,
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(strings.deleteWalletConfirmTitle),
        content: Text(strings.deleteWalletConfirmMsg),
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
      ref.read(walletNotifierProvider.notifier).deleteWallet(wallet.id);
    }
  }
}
