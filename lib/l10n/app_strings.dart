import 'package:flutter/material.dart';

class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  bool get isVi => languageCode == 'vi';

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale.languageCode);
  }

  static AppStrings fromLocale(Locale locale) {
    return AppStrings(locale.languageCode);
  }

  // App & Navigation
  String get appTitle => isVi ? 'Quản lý chi tiêu' : 'Expense Tracker';
  String get navDashboard => isVi ? 'Tổng quan' : 'Dashboard';
  String get navTransactions => isVi ? 'Giao dịch' : 'Transactions';
  String get navBudgets => isVi ? 'Ngân sách' : 'Budgets';
  String get navSettings => isVi ? 'Cài đặt' : 'Settings';

  // Dashboard & Balance Card
  String get currentBalance => isVi ? 'Số dư hiện tại' : 'Current Balance';
  String get totalIncome => isVi ? 'Thu nhập' : 'Income';
  String get totalExpenses => isVi ? 'Chi tiêu' : 'Expenses';
  String get recentTransactions => isVi ? 'Giao dịch gần đây' : 'Recent Transactions';
  String get viewAll => isVi ? 'Xem tất cả' : 'View All';
  String get noRecentTransactions => isVi ? 'Chưa có giao dịch nào' : 'No transactions yet';
  String get expenseByCategory => isVi ? 'Chi tiêu theo danh mục' : 'Expense by Category';
  String get noExpenseDataThisMonth =>
      isVi ? 'Chưa có dữ liệu chi tiêu tháng này' : 'No expense data this month';

  // Transactions Screen
  String get tabExpenses => isVi ? 'Khoản chi' : 'Expenses';
  String get tabIncome => isVi ? 'Khoản thu' : 'Income';
  String get addTransaction => isVi ? 'Thêm giao dịch' : 'Add Transaction';
  String get editTransaction => isVi ? 'Sửa giao dịch' : 'Edit Transaction';
  String get noTransactions => isVi ? 'Chưa có giao dịch' : 'No Transactions';
  String get noTransactionsDesc => isVi
      ? 'Thêm giao dịch đầu tiên để bắt đầu theo dõi chi tiêu.'
      : 'Add your first transaction to start tracking.';
  String get noItemsInTab => isVi ? 'Không có mục nào' : 'No items';
  String get noItemsInTabDesc => isVi ? 'Chưa có giao dịch trong tab này.' : 'No transactions in this tab.';
  String get transactionDeleted => isVi ? 'Đã xóa giao dịch' : 'Transaction deleted';
  String get deleteTransactionConfirmTitle => isVi ? 'Xóa giao dịch?' : 'Delete transaction?';
  String get deleteTransactionConfirmMsg => isVi
      ? 'Giao dịch này sẽ bị xóa khỏi thiết bị của bạn.'
      : 'This transaction will be deleted from your device.';
  String get cancel => isVi ? 'Hủy' : 'Cancel';
  String get delete => isVi ? 'Xóa' : 'Delete';
  String get save => isVi ? 'Lưu' : 'Save';
  String get saveChanges => isVi ? 'Lưu thay đổi' : 'Save Changes';

  // Add / Edit Transaction Form
  String get titleLabel => isVi ? 'Tiêu đề' : 'Title';
  String get titleRequired => isVi ? 'Vui lòng nhập tiêu đề' : 'Please enter a title';
  String get amountLabel => isVi ? 'Số tiền' : 'Amount';
  String get amountRequired => isVi ? 'Vui lòng nhập số tiền' : 'Please enter an amount';
  String get amountInvalid => isVi ? 'Vui lòng nhập số tiền hợp lệ' : 'Please enter a valid amount';
  String get categoryLabel => isVi ? 'Danh mục' : 'Category';
  String get dateLabel => isVi ? 'Ngày' : 'Date';
  String get notesLabel => isVi ? 'Ghi chú (tùy chọn)' : 'Notes (optional)';

  // Budgets Screen
  String get noBudgets => isVi ? 'Chưa có ngân sách' : 'No Budgets';
  String get noBudgetsDesc => isVi
      ? 'Đặt hạn mức theo danh mục để theo dõi chi tiêu tháng này.'
      : 'Set limits by category to track spending this month.';
  String get addBudget => isVi ? 'Thêm ngân sách' : 'Add Budget';
  String get editBudget => isVi ? 'Sửa ngân sách' : 'Edit Budget';
  String get budgetLimit => isVi ? 'Giới hạn ngân sách' : 'Budget Limit';
  String get budgetLimitRequired =>
      isVi ? 'Vui lòng nhập giới hạn ngân sách' : 'Please enter a budget limit';
  String get monthAndYear => isVi ? 'Tháng & năm' : 'Month & Year';
  String get selectMonth => isVi ? 'Chọn tháng' : 'Select Month';
  String get selectYear => isVi ? 'Chọn năm' : 'Select Year';
  String get monthPrefix => isVi ? 'Tháng' : 'Month';
  String get overBudget => isVi ? 'Vượt' : 'Over by';
  String get remaining => isVi ? 'Còn lại' : 'Remaining';
  String get deleteBudgetConfirmTitle => isVi ? 'Xóa ngân sách?' : 'Delete budget?';
  String get deleteBudgetConfirmMsg => isVi
      ? 'Ngân sách này sẽ bị xóa khỏi tháng hiện tại.'
      : 'This budget will be deleted from the current month.';
  String get editTooltip => isVi ? 'Chỉnh sửa' : 'Edit';

  // Settings & App Bar
  String get quickSettings => isVi ? 'Cài đặt nhanh' : 'Quick Settings';
  String get theme => isVi ? 'Giao diện' : 'Theme';
  String get themeSystem => isVi ? 'Theo hệ thống' : 'System Default';
  String get themeLight => isVi ? 'Sáng' : 'Light';
  String get themeDark => isVi ? 'Tối' : 'Dark';
  String get language => isVi ? 'Ngôn ngữ' : 'Language';
  String get languageVi => 'Tiếng Việt 🇻🇳';
  String get languageEn => 'English 🇬🇧';
  String get currency => isVi ? 'Đơn vị tiền tệ' : 'Currency';

  // Error messages
  String get errorGeneric => isVi ? 'Đã xảy ra lỗi' : 'An error occurred';
  String errorLoading(String msg) => isVi ? 'Lỗi: $msg' : 'Error: $msg';
  String errorLoadingStatus(String msg) =>
      isVi ? 'Lỗi khi tải trạng thái: $msg' : 'Error loading status: $msg';
  String errorLoadingExpense(String msg) =>
      isVi ? 'Lỗi khi tải chi tiêu: $msg' : 'Error loading expenses: $msg';

  // Category translation map
  static const Map<String, String> _viToEnCategory = {
    'Ăn uống': 'Food & Dining',
    'Mua sắm': 'Shopping',
    'Di chuyển': 'Transportation',
    'Hóa đơn & Tiện ích': 'Bills & Utilities',
    'Giải trí': 'Entertainment',
    'Sức khỏe': 'Health & Medical',
    'Giáo dục': 'Education',
    'Du lịch': 'Travel',
    'Quà tặng & Quyên góp': 'Gifts & Donations',
    'Khác': 'Other',
    'Tiền lương': 'Salary',
    'Freelance': 'Freelance',
    'Đầu tư': 'Investment',
    'Kinh doanh': 'Business',
    'Quà tặng': 'Gift',
  };

  static const Map<String, String> _enToViCategory = {
    'Food & Dining': 'Ăn uống',
    'Shopping': 'Mua sắm',
    'Transportation': 'Di chuyển',
    'Bills & Utilities': 'Hóa đơn & Tiện ích',
    'Entertainment': 'Giải trí',
    'Health & Medical': 'Sức khỏe',
    'Education': 'Giáo dục',
    'Travel': 'Du lịch',
    'Gifts & Donations': 'Quà tặng & Quyên góp',
    'Other': 'Khác',
    'Salary': 'Tiền lương',
    'Freelance': 'Freelance',
    'Investment': 'Đầu tư',
    'Business': 'Kinh doanh',
    'Gift': 'Quà tặng',
  };

  String getCategoryTitle(String key) {
    if (isVi) {
      return _enToViCategory[key] ?? key;
    } else {
      return _viToEnCategory[key] ?? key;
    }
  }
}
