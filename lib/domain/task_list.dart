import 'task.dart';

/// Совпадает ли календарный день (локальная таймзона устройства).
bool isSameLocalDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Задачи, относящиеся к дню [day] (ТЗ, FR-01).
List<Task> tasksOfDay(Iterable<Task> tasks, DateTime day) =>
    tasks.where((task) => isSameLocalDay(task.createdAt, day)).toList();

/// Порядок отображения (ТЗ, FR-01):
/// 1. Невыполненные — сверху, по порядку создания (position, затем createdAt);
/// 2. Выполненные — снизу, недавно отмеченные выше.
List<Task> sortForDisplay(Iterable<Task> tasks) {
  final active = <Task>[];
  final done = <Task>[];
  for (final task in tasks) {
    (task.isCompleted ? done : active).add(task);
  }
  active.sort((a, b) {
    final byPosition = a.position.compareTo(b.position);
    return byPosition != 0 ? byPosition : a.createdAt.compareTo(b.createdAt);
  });
  done.sort((a, b) {
    final aAt = a.completedAt ?? a.createdAt;
    final bAt = b.completedAt ?? b.createdAt;
    final byTime = bAt.compareTo(aAt);
    return byTime != 0 ? byTime : b.position.compareTo(a.position);
  });
  return <Task>[...active, ...done];
}
