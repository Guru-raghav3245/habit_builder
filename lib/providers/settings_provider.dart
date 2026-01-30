import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitit/models/settings.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  () => SettingsNotifier(),
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'theme_mode';
  static const _colorKey = 'seed_color';

  @override
  AppSettings build() {
    _loadSettings();
    return AppSettings(
      themeMode: ThemeMode.system,
      seedColor: Colors.deepPurple,
    );
  }

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
