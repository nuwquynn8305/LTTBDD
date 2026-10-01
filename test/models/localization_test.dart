import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/l10n/app_strings.dart';

void main() {
  group('AppStrings Localization Tests', () {
    test('Vietnamese strings return correct text', () {
      const strings = AppStrings('vi');
      expect(strings.isVi, isTrue);
      expect(strings.navDashboard, 'Tổng quan');
      expect(strings.navTransactions, 'Giao dịch');
      expect(strings.navBudgets, 'Ngân sách');
      expect(strings.currentBalance, 'Số dư hiện tại');
      expect(strings.getCategoryTitle('Food & Dining'), 'Ăn uống');
    });

    test('English strings return correct text', () {
      const strings = AppStrings('en');
      expect(strings.isVi, isFalse);
      expect(strings.navDashboard, 'Dashboard');
      expect(strings.navTransactions, 'Transactions');
      expect(strings.navBudgets, 'Budgets');
      expect(strings.currentBalance, 'Current Balance');
      expect(strings.getCategoryTitle('Ăn uống'), 'Food & Dining');
    });
  });
}
