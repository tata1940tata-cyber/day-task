import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/hive_task_repository.dart';
import 'domain/task.dart';
import 'domain/task_repository.dart';
import 'presentation/today/today_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  TaskRepository? storage;
  SettingsStore? settings;
  try {
    final repository = await HiveTaskRepository.open();
    storage = repository;
    settings = repository;
  } catch (_) {
    // Хранилище недоступно: приложение запускается с состоянием ошибки
    // загрузки и возможностью «Повторить» (ТЗ, раздел 4.2).
  }

  runApp(ProviderScope(
    overrides: <Override>[
      taskRepositoryProvider
          .overrideWithValue(storage ?? const _UnavailableRepository()),
      settingsStoreProvider.overrideWithValue(settings ?? _UnavailableSettings()),
    ],
    child: const DayTaskApp(),
  ));
}

/// Репозиторий-заглушка: сообщает об ошибке хранилища.
class _UnavailableRepository implements TaskRepository {
  const _UnavailableRepository();

  StorageException get _error => StorageException('Хранилище недоступно');

  @override
  Future<List<Task>> loadTasks() async => Future<List<Task>>.error(_error);

  @override
  Future<void> saveTask(Task task) async => Future<void>.error(_error);

  @override
  Future<void> deleteTask(String id) async => Future<void>.error(_error);
}

class _UnavailableSettings implements SettingsStore {
  @override
  String? read(String key) => null;

  @override
  Future<void> write(String key, String value) async {}
}
