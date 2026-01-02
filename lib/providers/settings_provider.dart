import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_builder/models/settings.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
    : super(
        AppSettings(themeMode: ThemeMode.system, seedColor: Colors.deepPurple),
      ) {
    _loadSettings();
  }

  static const _themeKey = 'theme_mode';
  static const _colorKey = 'seed_color';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    final colorValue = prefs.getInt(_colorKey) ?? Colors.deepPurple.value;

    state = AppSettings(
      themeMode: ThemeMode.values[themeIndex],
      seedColor: Color(colorValue),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
  }
}
