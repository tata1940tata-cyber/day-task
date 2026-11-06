import 'package:day_task/domain/task.dart';
import 'package:day_task/domain/task_repository.dart';

/// Хранилище в памяти для widget-тестов.
class InMemoryTaskRepository implements TaskRepository, SettingsStore {
  final Map<String, Task> tasks = <String, Task>{};
  final Map<String, String> settings = <String, String>{};

  /// Имитация сбоя записи.
  bool failSaves = false;

  void seed(Task task) => tasks[task.id] = task;

  @override
  Future<List<Task>> loadTasks() async => tasks.values.toList();

  @override
  Future<void> saveTask(Task task) async {
    if (failSaves) throw StorageException('Не удалось сохранить задачу');
    tasks[task.id] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    if (failSaves) throw StorageException('Не удалось удалить задачу');
    tasks.remove(id);
  }

  @override
  String? read(String key) => settings[key];

  @override
  Future<void> write(String key, String value) async {
    settings[key] = value;
  }
}
