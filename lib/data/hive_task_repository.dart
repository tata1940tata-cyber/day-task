import 'package:hive_flutter/hive_flutter.dart';

import '../domain/task.dart';
import '../domain/task_repository.dart';

/// Хранилище задач на Hive (ТЗ, раздел 3.4).
///
/// Задачи хранятся в box [tasksBoxName] как JSON-совместимые карты
/// (без codegen). Настройки — в box [metaBoxName].
class HiveTaskRepository implements TaskRepository, SettingsStore {
  HiveTaskRepository._(this._tasksBox, this._metaBox);

  static const String tasksBoxName = 'tasks_box';
  static const String metaBoxName = 'meta_box';
  static const String _schemaVersionKey = 'schemaVersion';

  final Box _tasksBox;
  final Box _metaBox;
  bool _readOnly = false;

  /// Открыть хранилище (инициализирует Hive для платформы).
  static Future<HiveTaskRepository> open() async {
    await Hive.initFlutter();
    return openBoxes();
  }

  /// Открыть уже инициализированный Hive (используется в тестах).
  static Future<HiveTaskRepository> openBoxes() async {
    final tasksBox = await Hive.openBox(tasksBoxName);
    final metaBox = await Hive.openBox(metaBoxName);
    final repository = HiveTaskRepository._(tasksBox, metaBox);
    await repository._checkSchema();
    return repository;
  }

  Future<void> _checkSchema() async {
    final stored = (_metaBox.get(_schemaVersionKey) as num?)?.toInt() ?? 0;
    if (stored > Task.currentSchemaVersion) {
      // Данные созданы более новой версией приложения: не удаляем их,
      // работаем в режиме только для чтения (ТЗ, раздел 3.4).
      _readOnly = true;
      return;
    }
    await _metaBox.put(_schemaVersionKey, Task.currentSchemaVersion);
  }

  void _ensureWritable() {
    if (_readOnly) {
      throw StorageException(
          'Данные созданы более новой версией приложения. Режим только для чтения.');
    }
  }

  @override
  Future<List<Task>> loadTasks() async {
    try {
      final tasks = <Task>[];
      for (final raw in _tasksBox.values) {
        if (raw is! Map) continue;
        try {
          tasks.add(Task.fromJson(Map<String, dynamic>.from(raw)));
        } catch (_) {
          // Повреждённая запись пропускается, остальные данные не теряются.
        }
      }
      return tasks;
    } catch (error) {
      throw StorageException('Не удалось прочитать задачи', error);
    }
  }

  @override
  Future<void> saveTask(Task task) async {
    _ensureWritable();
    try {
      await _tasksBox.put(task.id, task.toJson());
    } catch (error) {
      throw StorageException('Не удалось сохранить задачу', error);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _ensureWritable();
    try {
      await _tasksBox.delete(id);
    } catch (error) {
      throw StorageException('Не удалось удалить задачу', error);
    }
  }

  @override
  String? read(String key) => _metaBox.get(key) as String?;

  @override
  Future<void> write(String key, String value) async {
    try {
      await _metaBox.put(key, value);
    } catch (error) {
      throw StorageException('Не удалось сохранить настройки', error);
    }
  }
}
