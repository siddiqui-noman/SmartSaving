import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'smart_saving_theme_mode';

  @override
  ThemeMode build() {
    final stored = storageService.getString(_key);
    if (stored == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> toggle() async {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await storageService.setString(_key, 'light');
    } else {
      state = ThemeMode.dark;
      await storageService.setString(_key, 'dark');
    }
  }

  bool get isDark => state == ThemeMode.dark;
}
