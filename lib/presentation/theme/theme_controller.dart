import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/task_repository.dart';
import '../today/today_controller.dart' show settingsStoreProvider;

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

/// Тема приложения: системная → светлая → тёмная → системная (ТЗ, A10).
class ThemeController extends Notifier<ThemeMode> {
  static const String _key = 'themeMode';

  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  ThemeMode build() {
    switch (_store.read(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await _store.write(_key, mode.name);
    } on StorageException {
      // Настройка темы не критична: ошибка сохранения игнорируется.
    }
  }

  /// Переключить тему по кругу.
  Future<void> cycle() async {
    const order = <ThemeMode>[
      ThemeMode.system,
      ThemeMode.light,
      ThemeMode.dark,
    ];
    final next = order[(order.indexOf(state) + 1) % order.length];
    await setMode(next);
  }
}
