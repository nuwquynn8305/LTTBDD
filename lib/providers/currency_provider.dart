import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_currency.dart';
import '../services/storage_service.dart';

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  final StorageService _storageService;

  CurrencyNotifier(this._storageService)
      : super(AppCurrency.fromCode(_storageService.getCurrencyCode()));

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    await _storageService.setCurrencyCode(currency.code);
  }

  Future<void> setCurrencyByCode(String code) async {
    final currency = AppCurrency.fromCode(code);
    await setCurrency(currency);
  }
}

final currencyNotifierProvider =
    StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  final storageService = StorageService();
  return CurrencyNotifier(storageService);
});
