import 'task.dart';

/// Интерфейс хранилища задач (слой данных заменяем — см. ТЗ, раздел 3.1).
abstract class TaskRepository {
  /// Загрузить все задачи с устройства.
  Future<List<Task>> loadTasks();

  /// Сохранить (создать или обновить) задачу.
  Future<void> saveTask(Task task);

  /// Удалить задачу по идентификатору.
  Future<void> deleteTask(String id);
}

/// Простое хранилище настроек (тема и т.п.).
abstract class SettingsStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

/// Ошибка локального хранилища. Данные при возникновении не удаляются.
class StorageException implements Exception {
  StorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'StorageException: $message${cause == null ? '' : ' ($cause)'}';
}
