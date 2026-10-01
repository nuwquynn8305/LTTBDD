import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/app_currency.dart';

void main() {
  group('AppCurrency Model Tests', () {
    test('VND currency formats correctly without decimals and with symbol', () {
      const vnd = AppCurrency.vnd;
      expect(vnd.code, 'VND');
      expect(vnd.symbol, '₫');
      final formatted = vnd.format(150000);
      expect(formatted.contains('150'), isTrue);
      expect(formatted.contains('₫'), isTrue);
    });

    test('USD currency formats with decimals and dollar sign', () {
      const usd = AppCurrency.usd;
      expect(usd.code, 'USD');
      expect(usd.symbol, r'$');
      final formatted = usd.format(150.5);
      expect(formatted.contains('150.50') || formatted.contains('150,50') || formatted.contains('150.5'), isTrue);
      expect(formatted.contains(r'$'), isTrue);
    });

    test('fromCode returns expected currency or defaults to VND', () {
      expect(AppCurrency.fromCode('USD'), AppCurrency.usd);
      expect(AppCurrency.fromCode('EUR'), AppCurrency.eur);
      expect(AppCurrency.fromCode('JPY'), AppCurrency.jpy);
      expect(AppCurrency.fromCode('GBP'), AppCurrency.gbp);
      expect(AppCurrency.fromCode('UNKNOWN'), AppCurrency.vnd);
      expect(AppCurrency.fromCode(null), AppCurrency.vnd);
    });

    test('formatWithSign formats income and expense signs', () {
      const vnd = AppCurrency.vnd;
      final income = vnd.formatWithSign(50000, isIncome: true);
      final expense = vnd.formatWithSign(50000, isIncome: false);
      expect(income.startsWith('+'), isTrue);
      expect(expense.startsWith('-'), isTrue);
    });
  });
}
