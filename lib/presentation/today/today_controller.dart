import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/task.dart';
import '../../domain/task_list.dart';
import '../../domain/task_repository.dart';
import '../../domain/task_validation.dart';

/// Хранилище задач (переопределяется в main и в тестах).
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => throw UnimplementedError('taskRepositoryProvider должен быть переопределён'),
);

/// Хранилище настроек.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider должен быть переопределён'),
);

final todayControllerProvider =
    NotifierProvider<TodayController, TodayState>(TodayController.new);

enum TodayStatus { loading, ready, error }

/// Результат добавления задачи (FR-02).
enum AddTaskError { empty, tooLong, limitReached, storage }

/// Состояние экрана «Сегодня».
class TodayState {
  const TodayState({
    required this.status,
    required this.allTasks,
    required this.today,
    this.errorMessage,
  });

  final TodayStatus status;

  /// Все задачи с устройства (включая задачи прошлых дней — они не показываются).
  final List<Task> allTasks;

  /// Текущий день (локальная таймзона устройства).
  final DateTime today;

  /// Последняя ошибка хранилища (для показа сообщения).
  final String? errorMessage;

  /// Задачи текущего дня в порядке отображения (FR-01).
  List<Task> get todayTasks => sortForDisplay(tasksOfDay(allTasks, today));

  int get todayTotal => tasksOfDay(allTasks, today).length;

  int get todayDoneCount =>
      tasksOfDay(allTasks, today).where((task) => task.isCompleted).length;

  bool get isLimitReached => todayTotal >= TitleValidation.maxTasksPerDay;

  /// Следующая позиция для новой задачи.
  int get nextPosition {
    var max = -1;
    for (final task in allTasks) {
      if (task.position > max) max = task.position;
    }
    return max + 1;
  }

  TodayState copyWith({
    TodayStatus? status,
    List<Task>? allTasks,
    DateTime? today,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodayState(
      status: status ?? this.status,
      allTasks: allTasks ?? this.allTasks,
      today: today ?? this.today,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Логика экрана «Сегодня»: загрузка, добавление, отметка, удаление.
class TodayController extends Notifier<TodayState> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  TodayState build() {
    Future<void>(_load);
    return TodayState(
      status: TodayStatus.loading,
      allTasks: const <Task>[],
      today: DateTime.now(),
    );
  }

  Future<void> _load() async {
    try {
      final tasks = await _repository.loadTasks();
      state = TodayState(
        status: TodayStatus.ready,
        allTasks: tasks,
        today: DateTime.now(),
      );
    } on StorageException catch (error) {
      state = TodayState(
        status: TodayStatus.error,
        allTasks: const <Task>[],
        today: DateTime.now(),
        errorMessage: error.message,
      );
    }
  }

  /// Повторная загрузка после ошибки.
  Future<void> retry() async {
    state = state.copyWith(status: TodayStatus.loading, clearError: true);
    await _load();
  }

  /// Добавить задачу. Возвращает ошибку или `null` при успехе (FR-02).
  Future<AddTaskError?> addTask(String rawTitle) async {
    final validationError = TitleValidation.validate(rawTitle);
    if (validationError == TitleValidationError.empty) {
      return AddTaskError.empty;
    }
    if (validationError == TitleValidationError.tooLong) {
      return AddTaskError.tooLong;
    }
    if (state.isLimitReached) {
      return AddTaskError.limitReached;
    }

    final task = Task(
      id: _newId(),
      title: TitleValidation.normalize(rawTitle),
      createdAt: DateTime.now(),
      position: state.nextPosition,
    );
    try {
      await _repository.saveTask(task);
      state = state.copyWith(allTasks: <Task>[...state.allTasks, task]);
      return null;
    } on StorageException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      return AddTaskError.storage;
    }
  }

  /// Переключить отметку о выполнении (FR-03). Обновление оптимистичное.
  ///
  /// Статус берётся из актуального состояния (а не из снимка в виджете),
  /// чтобы быстрые повторные нажатия учитывались корректно (чёт/нечёт).
  Future<void> toggleTask(Task task) async {
    Task? current;
    for (final item in state.allTasks) {
      if (item.id == task.id) {
        current = item;
        break;
      }
    }
    if (current == null) return;
    final updated = current.isCompleted
        ? current.uncomplete()
        : current.complete(DateTime.now());
    final previous = state.allTasks;
    state = state.copyWith(
      allTasks: <Task>[
        for (final item in previous) item.id == task.id ? updated : item,
      ],
    );
    try {
      await _repository.saveTask(updated);
    } on StorageException catch (error) {
      state = state.copyWith(allTasks: previous, errorMessage: error.message);
    }
  }

  /// Удалить задачу (FR-04).
  Future<void> deleteTask(Task task) async {
    final previous = state.allTasks;
    state = state.copyWith(
      allTasks: previous.where((item) => item.id != task.id).toList(),
    );
    try {
      await _repository.deleteTask(task.id);
    } on StorageException catch (error) {
      state = state.copyWith(allTasks: previous, errorMessage: error.message);
    }
  }

  /// Отменить удаление: вернуть задачу с исходными полями и позицией (FR-04).
  Future<void> undoDelete(Task task) async {
    try {
      await _repository.saveTask(task);
      state = state.copyWith(allTasks: <Task>[...state.allTasks, task]);
    } on StorageException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    }
  }

  /// Проверить смену дня при возвращении приложения на экран (FR-01, S3).
  void refreshIfDayChanged() {
    final now = DateTime.now();
    if (!isSameLocalDay(now, state.today)) {
      state = state.copyWith(today: now);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

String _newId() => const Uuid().v4();
