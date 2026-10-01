import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

ThemeMode _themeModeFromString(String mode) {
  return switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

String _themeModeToString(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storageService;

  ThemeNotifier(this._storageService)
      : super(_themeModeFromString(_storageService.getThemeMode()));

  void setTheme(ThemeMode theme) {
    state = theme;
    _storageService.setThemeMode(_themeModeToString(theme));
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setTheme(newMode);
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((
  ref,
) {
  final storageService = StorageService();
  return ThemeNotifier(storageService);
});

final lightThemeProvider = Provider<ThemeData>((ref) => AppTheme.light());

final darkThemeProvider = Provider<ThemeData>((ref) => AppTheme.dark());
