import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/wallet.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';
import '../screens/add_wallet_screen.dart';
import '../screens/transfer_screen.dart';
import '../screens/wallets_screen.dart';

class WalletsSummaryWidget extends ConsumerWidget {
  const WalletsSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final locale = ref.watch(localeNotifierProvider);
    final currency = ref.watch(currencyNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  strings.myWallets,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.sync_alt, size: 18),
                tooltip: strings.transferBetweenWallets,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransferScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletsScreen(),
                    ),
                  );
                },
                child: Text(strings.viewAll),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: walletsAsync.when(
            data: (wallets) {
              if (wallets.isEmpty) {
                return Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddWalletScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(strings.addWallet),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: wallets.length + 1,
                itemBuilder: (context, index) {
                  if (index == wallets.length) {
                    // Add new wallet button card
                    return Container(
                      width: 110,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddWalletScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                strings.addWallet,
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final wallet = wallets[index];
                  return _WalletCardItem(
                    wallet: wallet,
                    strings: strings,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(strings.errorLoading('$error'))),
          ),
        ),
      ],
    );
  }
}

class _WalletCardItem extends ConsumerWidget {
  final Wallet wallet;
  final AppStrings strings;

  const _WalletCardItem({
    required this.wallet,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));
    final currency = ref.watch(currencyNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalletsScreen(initialWalletId: wallet.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: wallet.color.withValues(alpha: 0.18),
                      foregroundColor: wallet.color,
                      child: Icon(wallet.iconData, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        wallet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (wallet.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '★',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.getWalletTypeName(wallet.type),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    balanceAsync.when(
                      data: (balance) {
                        final isNegative = balance < 0;
                        return Text(
                          currency.format(balance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isNegative
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 16,
                        width: 60,
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, __) => Text(strings.errorGeneric),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
