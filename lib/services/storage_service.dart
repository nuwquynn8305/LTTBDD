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

      // Seed sample transactions & budgets if empty
      await seedSampleData();

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

  /// Nạp dữ liệu mẫu phong phú (Transactions, Budgets) phục vụ demo và trải nghiệm
  Future<void> seedSampleData({bool force = false}) async {
    final transBox = Hive.box<Transaction>(transactionBoxName);
    final budgetBox = Hive.box<Budget>(budgetBoxName);

    if (force) {
      await transBox.clear();
      await budgetBox.clear();
    } else if (transBox.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    DateTime d(int daysAgo, int hour, int minute) {
      final target = now.subtract(Duration(days: daysAgo));
      return DateTime(target.year, target.month, target.day, hour, minute);
    }

    final sampleTransactions = [
      Transaction(
        id: 'tx_seed_1',
        title: 'Tiền lương chuyển khoản',
        amount: 22000000,
        category: 'Tiền lương',
        date: d(15, 9, 0),
        type: 'income',
        walletId: 'wallet_bank',
        notes: 'Lương công ty chuyển khoản qua ngân hàng',
      ),
      Transaction(
        id: 'tx_seed_2',
        title: 'Tiền thuê căn hộ & dịch vụ',
        amount: 4200000,
        category: 'Hóa đơn & Tiện ích',
        date: d(14, 11, 0),
        type: 'expense',
        walletId: 'wallet_bank',
        notes: 'Tiền nhà đầu tháng',
      ),
      Transaction(
        id: 'tx_seed_3',
        title: 'Thưởng dự án hoàn thành',
        amount: 4500000,
        category: 'Freelance',
        date: d(12, 15, 30),
        type: 'income',
        walletId: 'wallet_bank',
        notes: 'Thưởng KPI giai đoạn 1',
      ),
      Transaction(
        id: 'tx_seed_4',
        title: 'Gửi tiết kiệm tích lũy',
        amount: 5000000,
        category: 'Chuyển tiền',
        date: d(10, 8, 30),
        type: 'transfer',
        walletId: 'wallet_bank',
        toWalletId: 'wallet_savings',
        notes: 'Trích quỹ tiết kiệm định kỳ',
      ),
      Transaction(
        id: 'tx_seed_5',
        title: 'Tiền điện nước & Internet',
        amount: 850000,
        category: 'Hóa đơn & Tiện ích',
        date: d(8, 14, 0),
        type: 'expense',
        walletId: 'wallet_bank',
        notes: 'Thanh toán hóa đơn VNPT và EVN',
      ),
      Transaction(
        id: 'tx_seed_6',
        title: 'Rút tiền ATM chi tiêu',
        amount: 3000000,
        category: 'Chuyển tiền',
        date: d(6, 10, 0),
        type: 'transfer',
        walletId: 'wallet_bank',
        toWalletId: 'wallet_cash',
        notes: 'Rút tiền mặt chi tiêu tuần',
      ),
      Transaction(
        id: 'tx_seed_7',
        title: 'Mua sách lập trình Flutter',
        amount: 320000,
        category: 'Giáo dục',
        date: d(5, 16, 20),
        type: 'expense',
        walletId: 'wallet_credit',
        notes: 'Sách kiến trúc phần mềm',
      ),
      Transaction(
        id: 'tx_seed_8',
        title: 'Xem phim rạp CGV cuối tuần',
        amount: 190000,
        category: 'Giải trí',
        date: d(4, 21, 0),
        type: 'expense',
        walletId: 'wallet_cash',
        notes: 'Vé xem phim và bỏng ngô',
      ),
      Transaction(
        id: 'tx_seed_9',
        title: 'Mua sắm siêu thị cuối tuần',
        amount: 1150000,
        category: 'Mua sắm',
        date: d(3, 18, 45),
        type: 'expense',
        walletId: 'wallet_credit',
        notes: 'Thực phẩm và đồ dùng gia đình',
      ),
      Transaction(
        id: 'tx_seed_10',
        title: 'Ăn tối liên hoan bạn bè',
        amount: 480000,
        category: 'Ăn uống',
        date: d(2, 20, 0),
        type: 'expense',
        walletId: 'wallet_cash',
        notes: 'Buffet lẩu nướng',
      ),
      Transaction(
        id: 'tx_seed_11',
        title: 'Đổ xăng xe máy',
        amount: 120000,
        category: 'Di chuyển',
        date: d(1, 7, 30),
        type: 'expense',
        walletId: 'wallet_cash',
      ),
      Transaction(
        id: 'tx_seed_12',
        title: 'Cà phê sáng & ăn sáng',
        amount: 55000,
        category: 'Ăn uống',
        date: d(0, 8, 15),
        type: 'expense',
        walletId: 'wallet_cash',
      ),
      Transaction(
        id: 'tx_seed_13',
        title: 'Tiền lãi đầu tư sinh lời',
        amount: 420000,
        category: 'Đầu tư',
        date: d(0, 10, 0),
        type: 'income',
        walletId: 'wallet_bank',
      ),
    ];

    for (var tx in sampleTransactions) {
      await transBox.put(tx.id, tx);
    }

    if (budgetBox.isEmpty || force) {
      final sampleBudgets = [
        Budget(
          id: 'bg_seed_food',
          category: 'Ăn uống',
          limit: 2500000,
          month: now.month,
          year: now.year,
        ),
        Budget(
          id: 'bg_seed_shopping',
          category: 'Mua sắm',
          limit: 2000000,
          month: now.month,
          year: now.year,
        ),
        Budget(
          id: 'bg_seed_bills',
          category: 'Hóa đơn & Tiện ích',
          limit: 6000000,
          month: now.month,
          year: now.year,
        ),
        Budget(
          id: 'bg_seed_transport',
          category: 'Di chuyển',
          limit: 800000,
          month: now.month,
          year: now.year,
        ),
      ];

      for (var bg in sampleBudgets) {
        await budgetBox.put(bg.id, bg);
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
