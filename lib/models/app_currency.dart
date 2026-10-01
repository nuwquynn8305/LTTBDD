import 'package:intl/intl.dart';

enum CurrencyType { vnd, usd, eur, jpy, gbp }

class AppCurrency {
  final CurrencyType type;
  final String code;
  final String name;
  final String symbol;
  final String locale;
  final int decimalDigits;
  final bool symbolOnRight;

  const AppCurrency({
    required this.type,
    required this.code,
    required this.name,
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
    this.symbolOnRight = false,
  });

  static const AppCurrency vnd = AppCurrency(
    type: CurrencyType.vnd,
    code: 'VND',
    name: 'Việt Nam Đồng (VNĐ)',
    symbol: '₫',
    locale: 'vi_VN',
    decimalDigits: 0,
    symbolOnRight: true,
  );

  static const AppCurrency usd = AppCurrency(
    type: CurrencyType.usd,
    code: 'USD',
    name: 'US Dollar (USD)',
    symbol: r'$',
    locale: 'en_US',
    decimalDigits: 2,
    symbolOnRight: false,
  );

  static const AppCurrency eur = AppCurrency(
    type: CurrencyType.eur,
    code: 'EUR',
    name: 'Euro (EUR)',
    symbol: '€',
    locale: 'de_DE',
    decimalDigits: 2,
    symbolOnRight: true,
  );

  static const AppCurrency jpy = AppCurrency(
    type: CurrencyType.jpy,
    code: 'JPY',
    name: 'Japanese Yen (JPY)',
    symbol: '¥',
    locale: 'ja_JP',
    decimalDigits: 0,
    symbolOnRight: false,
  );

  static const AppCurrency gbp = AppCurrency(
    type: CurrencyType.gbp,
    code: 'GBP',
    name: 'British Pound (GBP)',
    symbol: '£',
    locale: 'en_GB',
    decimalDigits: 2,
    symbolOnRight: false,
  );

  static const List<AppCurrency> supportedCurrencies = [
    vnd,
    usd,
    eur,
    jpy,
    gbp,
  ];

  static AppCurrency fromCode(String? code) {
    if (code == null) return vnd;
    return supportedCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => vnd,
    );
  }

  String format(double amount) {
    // If the currency has 2 decimal digits but amount is a whole number or .0,
    // we format with standard currency formatter
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  String formatWithSign(double amount, {required bool isIncome}) {
    final sign = isIncome ? '+' : '-';
    return '$sign${format(amount)}';
  }
}
