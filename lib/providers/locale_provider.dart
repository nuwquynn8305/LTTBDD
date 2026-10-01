import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final StorageService _storageService;

  LocaleNotifier(this._storageService)
      : super(Locale(_storageService.getLanguageCode()));

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storageService.setLanguageCode(locale.languageCode);
  }

  Future<void> setLanguageCode(String languageCode) async {
    final locale = Locale(languageCode);
    await setLocale(locale);
  }

  void toggleLocale() {
    if (state.languageCode == 'vi') {
      setLanguageCode('en');
    } else {
      setLanguageCode('vi');
    }
  }
}

final localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storageService = StorageService();
  return LocaleNotifier(storageService);
});
