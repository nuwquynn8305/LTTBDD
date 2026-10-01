import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setTheme(ThemeMode theme) {
    state = theme;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((
  ref,
) {
  return ThemeNotifier();
});

final lightThemeProvider = Provider<ThemeData>((ref) => AppTheme.light());

final darkThemeProvider = Provider<ThemeData>((ref) => AppTheme.dark());
