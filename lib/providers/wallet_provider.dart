import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/storage_service.dart';
import 'transaction_provider.dart';

final walletsProvider = FutureProvider<List<Wallet>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getAllWallets();
});

final defaultWalletProvider = FutureProvider<Wallet?>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  if (wallets.isEmpty) return null;
  return wallets.firstWhere((w) => w.isDefault, orElse: () => wallets.first);
});

// Calculate live balance for a specific wallet
final walletBalanceProvider =
    FutureProvider.family<double, String>((ref, walletId) async {
  final wallets = await ref.watch(walletsProvider.future);
  final transactions = await ref.watch(transactionsProvider.future);

  final wallet = wallets.firstWhere(
    (w) => w.id == walletId,
    orElse: () => Wallet(
      id: '',
      name: '',
      type: 'other',
      initialBalance: 0,
      icon: 'wallet',
      colorValue: 0,
      createdAt: DateTime.now(),
    ),
  );

  double balance = wallet.initialBalance;

  for (final t in transactions) {
    if (t.type == 'income' && t.walletId == walletId) {
      balance += t.amount;
    } else if (t.type == 'expense' && t.walletId == walletId) {
      balance -= t.amount;
    } else if (t.type == 'transfer') {
      if (t.walletId == walletId) {
        // Outgoing transfer
        balance -= t.amount;
      }
      if (t.toWalletId == walletId) {
        // Incoming transfer
        balance += t.amount;
      }
    }
  }

  return balance;
});

// Total net worth across all wallets (Cash + Bank + Savings - Credit Card debt if negative)
final totalNetWorthProvider = FutureProvider<double>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  double total = 0.0;
  for (final w in wallets) {
    final balance = await ref.watch(walletBalanceProvider(w.id).future);
    total += balance;
  }
  return total;
});

// Currently selected wallet filter for transaction list
final selectedWalletFilterProvider = StateProvider<String?>((ref) => null);

// Transactions filtered by selected wallet filter
final filteredTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final all = await ref.watch(transactionsProvider.future);
  final filterId = ref.watch(selectedWalletFilterProvider);
  if (filterId == null) return all;
  return all.where((t) => t.walletId == filterId || t.toWalletId == filterId).toList();
});

class WalletNotifier extends StateNotifier<AsyncValue<void>> {
  final StorageService _storageService;
  final Ref _ref;

  WalletNotifier(this._storageService, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> addWallet(Wallet wallet) async {
    state = const AsyncValue.loading();
    try {
      await _storageService.addWallet(wallet);
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    state = const AsyncValue.loading();
    try {
      await _storageService.updateWallet(wallet);
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteWallet(String id) async {
    state = const AsyncValue.loading();
    try {
      await _storageService.deleteWallet(id);
      state = const AsyncValue.data(null);
      _invalidateProviders();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _invalidateProviders() {
    _ref.invalidate(walletsProvider);
    _ref.invalidate(defaultWalletProvider);
    _ref.invalidate(totalNetWorthProvider);
    _ref.invalidate(balanceProvider);
  }
}

final walletNotifierProvider =
    StateNotifierProvider<WalletNotifier, AsyncValue<void>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return WalletNotifier(storageService, ref);
});
