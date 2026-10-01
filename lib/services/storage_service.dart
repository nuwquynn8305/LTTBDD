import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class StorageService {
  static const String transactionBoxName = 'transactions';
  static const String budgetBoxName = 'budgets';
  static const String walletBoxName = 'wallets';
  static const String settingsBoxName = 'settings';

  static final StorageService _instance = StorageService._internal();
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> init() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for ongoing initialization
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return;
    }

    _isInitializing = true;

    try {
      // Initialize Hive once
      if (!Hive.isAdapterRegistered(0)) {
        await Hive.initFlutter();
        Hive.registerAdapter(TransactionAdapter());
        Hive.registerAdapter(BudgetAdapter());
        Hive.registerAdapter(WalletAdapter());
      }

      // Try to open boxes if not already open
      if (!Hive.isBoxOpen(transactionBoxName)) {
        await Hive.openBox<Transaction>(transactionBoxName);
      }

      if (!Hive.isBoxOpen(budgetBoxName)) {
        await Hive.openBox<Budget>(budgetBoxName);
      }

      if (!Hive.isBoxOpen(walletBoxName)) {
        await Hive.openBox<Wallet>(walletBoxName);
      }

      if (!Hive.isBoxOpen(settingsBoxName)) {
        await Hive.openBox(settingsBoxName);
      }

      // Seed initial wallets if empty
      await _seedDefaultWallets();

      _isInitialized = true;
    } catch (e) {
      debugPrint('StorageService init error: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _seedDefaultWallets() async {
    final box = Hive.box<Wallet>(walletBoxName);
    if (box.isEmpty) {
      final defaultWallets = [
        Wallet(
          id: 'wallet_cash',
          name: 'Ví tiền mặt',
          type: 'cash',
          initialBalance: 0,
          icon: 'cash',
          colorValue: 0xFF2E7D32, // Green
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Wallet(
          id: 'wallet_bank',
          name: 'Tài khoản ngân hàng',
          type: 'bank',
          initialBalance: 0,
          icon: 'bank',
          colorValue: 0xFF1565C0, // Blue
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        Wallet(
          id: 'wallet_credit',
          name: 'Thẻ tín dụng',
          type: 'credit',
          initialBalance: 0,
          icon: 'credit',
          colorValue: 0xFFD84315, // Deep Orange
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        Wallet(
          id: 'wallet_savings',
          name: 'Sổ tiết kiệm',
          type: 'savings',
          initialBalance: 0,
          icon: 'savings',
          colorValue: 0xFFF57F17, // Amber
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      for (var w in defaultWallets) {
        await box.put(w.id, w);
      }
    }
  }

  // Wallet methods
  Future<List<Wallet>> getAllWallets() async {
    await init();
    final box = Hive.box<Wallet>(walletBoxName);
    return box.values.toList();
  }

  Future<Wallet?> getWalletById(String id) async {
    await init();
    final box = Hive.box<Wallet>(walletBoxName);
    return box.get(id);
  }

  Future<void> addWallet(Wallet wallet) async {
    await init();
    final box = Hive.box<Wallet>(walletBoxName);
    if (wallet.isDefault) {
      for (var w in box.values) {
        if (w.isDefault && w.id != wallet.id) {
          await box.put(w.id, w.copyWith(isDefault: false));
        }
      }
    }
    await box.put(wallet.id, wallet);
  }

  Future<void> updateWallet(Wallet wallet) async {
    await init();
    final box = Hive.box<Wallet>(walletBoxName);
    if (wallet.isDefault) {
      for (var w in box.values) {
        if (w.isDefault && w.id != wallet.id) {
          await box.put(w.id, w.copyWith(isDefault: false));
        }
      }
    }
    await box.put(wallet.id, wallet);
  }

  Future<void> deleteWallet(String id) async {
    await init();
    final box = Hive.box<Wallet>(walletBoxName);
    await box.delete(id);
  }

  // Settings methods
  String getCurrencyCode() {
    if (!Hive.isBoxOpen(settingsBoxName)) return 'VND';
    final box = Hive.box(settingsBoxName);
    return box.get('currency', defaultValue: 'VND') as String;
  }

  Future<void> setCurrencyCode(String code) async {
    await init();
    final box = Hive.box(settingsBoxName);
    await box.put('currency', code);
  }

  String getLanguageCode() {
    if (!Hive.isBoxOpen(settingsBoxName)) return 'vi';
    final box = Hive.box(settingsBoxName);
    return box.get('language', defaultValue: 'vi') as String;
  }

  Future<void> setLanguageCode(String code) async {
    await init();
    final box = Hive.box(settingsBoxName);
    await box.put('language', code);
  }

  String getThemeMode() {
    if (!Hive.isBoxOpen(settingsBoxName)) return 'system';
    final box = Hive.box(settingsBoxName);
    return box.get('theme', defaultValue: 'system') as String;
  }

  Future<void> setThemeMode(String mode) async {
    await init();
    final box = Hive.box(settingsBoxName);
    await box.put('theme', mode);
  }

  // Transaction methods
  Future<void> addTransaction(Transaction transaction) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    await box.put(transaction.id, transaction);
  }

  Future<List<Transaction>> getAllTransactions() async {
    await init();
    final box = Hive.box<Transaction>(transactionBoxName);
    return box.values.toList();
  }

  Future<List<Transaction>> getTransactionsByWallet(String walletId) async {
    await init();
    final box = Hive.box<Transaction>(transactionBoxName);
    return box.values.where((t) {
      return t.walletId == walletId || t.toWalletId == walletId;
    }).toList();
  }

  Future<List<Transaction>> getTransactionsByType(String type) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    return box.values.where((t) => t.type == type).toList();
  }

  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    return box.values.where((t) => t.category == category).toList();
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    await init();
    final box = Hive.box<Transaction>(transactionBoxName);
    final transactions = box.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions.take(limit).toList();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    await box.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    await box.delete(id);
  }

  Future<Transaction?> getTransactionById(String id) async {
    final box = Hive.box<Transaction>(transactionBoxName);
    return box.get(id);
  }

  Future<double> getTotalIncome() async {
    await init();
    final box = Hive.box<Transaction>(transactionBoxName);
    final transactions = box.values.where((t) => t.type == 'income').toList();
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  Future<double> getTotalExpenses() async {
    await init();
    final box = Hive.box<Transaction>(transactionBoxName);
    final transactions = box.values.where((t) => t.type == 'expense').toList();
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expenses = await getTotalExpenses();
    return income - expenses;
  }

  // Budget methods
  Future<void> addBudget(Budget budget) async {
    final box = Hive.box<Budget>(budgetBoxName);
    await box.put(budget.id, budget);
  }

  Future<List<Budget>> getAllBudgets() async {
    await init();
    final box = Hive.box<Budget>(budgetBoxName);
    return box.values.toList();
  }

  Future<List<Budget>> getBudgetsForMonth(int month, int year) async {
    await init();
    final box = Hive.box<Budget>(budgetBoxName);
    return box.values.where((b) => b.month == month && b.year == year).toList();
  }

  Future<Budget?> getBudgetByCategory(
    String category,
    int month,
    int year,
  ) async {
    final box = Hive.box<Budget>(budgetBoxName);
    return box.values.firstWhere(
      (b) => b.category == category && b.month == month && b.year == year,
      orElse: () => Budget(id: '', category: '', limit: 0, month: 0, year: 0),
    );
  }

  Future<void> updateBudget(Budget budget) async {
    final box = Hive.box<Budget>(budgetBoxName);
    await box.put(budget.id, budget);
  }

  Future<void> deleteBudget(String id) async {
    final box = Hive.box<Budget>(budgetBoxName);
    await box.delete(id);
  }

  Future<Budget?> getBudgetById(String id) async {
    final box = Hive.box<Budget>(budgetBoxName);
    return box.get(id);
  }

  Future<Map<String, double>> getSpendingByCategory(int month, int year) async {
    await init();
    final box = Hive.box<Transaction>(transactionBoxName);
    final transactions = box.values.where((t) {
      return t.type == 'expense' &&
          t.date.month == month &&
          t.date.year == year;
    }).toList();

    final Map<String, double> spending = {};
    for (var transaction in transactions) {
      spending[transaction.category] =
          (spending[transaction.category] ?? 0) + transaction.amount;
    }

    return spending;
  }

  Future<Map<String, double>> getBudgetStatus(int month, int year) async {
    final budgets = await getBudgetsForMonth(month, year);
    final spending = await getSpendingByCategory(month, year);

    final Map<String, double> status = {};
    for (var budget in budgets) {
      final spent = spending[budget.category] ?? 0;
      final remaining = budget.limit - spent;
      status[budget.category] = remaining;
    }

    return status;
  }

  Future<void> close() async {
    await Hive.close();
  }
}
