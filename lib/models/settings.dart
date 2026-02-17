import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Color seedColor;

  AppSettings({required this.themeMode, required this.seedColor});

  AppSettings copyWith({ThemeMode? themeMode, Color? seedColor}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}
