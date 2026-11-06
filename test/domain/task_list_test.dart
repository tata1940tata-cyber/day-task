import 'package:day_task/domain/task.dart';
import 'package:day_task/domain/task_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Task task(
    String id, {
    bool done = false,
    int position = 0,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: 'Задача $id',
      createdAt: createdAt ?? DateTime(2026, 11, 5, 9),
      completedAt: completedAt,
      isCompleted: done,
      position: position,
    );
  }

  group('isSameLocalDay', () {
    test('одинаковые даты в разное время — совпадают', () {
      expect(
        isSameLocalDay(DateTime(2026, 11, 5, 0), DateTime(2026, 11, 5, 23, 59)),
        isTrue,
      );
    });

    test('разные даты — не совпадают', () {
      expect(isSameLocalDay(DateTime(2026, 11, 5), DateTime(2026, 11, 6)), isFalse);
    });
  });

  group('tasksOfDay', () {
    test('фильтрует задачи по дню создания (FR-01)', () {
      final tasks = <Task>[
        task('today-1', createdAt: DateTime(2026, 11, 5, 8)),
        task('yesterday', createdAt: DateTime(2026, 11, 4, 22)),
        task('today-2', createdAt: DateTime(2026, 11, 5, 18)),
      ];

      final result = tasksOfDay(tasks, DateTime(2026, 11, 5, 12));

      expect(result.map((t) => t.id), ['today-1', 'today-2']);
    });
  });

  group('sortForDisplay (FR-01)', () {
    test('невыполненные сверху по позиции, выполненные внизу', () {
      final tasks = <Task>[
        task('d1', done: true, position: 0, completedAt: DateTime(2026, 11, 5, 8)),
        task('a2', position: 2),
        task('a1', position: 1),
        task('d2', done: true, position: 3, completedAt: DateTime(2026, 11, 5, 10)),
      ];

      final result = sortForDisplay(tasks);

      expect(result.map((t) => t.id).toList(), ['a1', 'a2', 'd2', 'd1']);
    });

    test('невыполненные с равной позицией — по времени создания', () {
      final tasks = <Task>[
        task('later', createdAt: DateTime(2026, 11, 5, 11)),
        task('earlier', createdAt: DateTime(2026, 11, 5, 8)),
      ];

      final result = sortForDisplay(tasks);

      expect(result.map((t) => t.id).toList(), ['earlier', 'later']);
    });

    test('недавно выполненные — выше в группе выполненных', () {
      final tasks = <Task>[
        task('old', done: true, completedAt: DateTime(2026, 11, 5, 7)),
        task('new', done: true, completedAt: DateTime(2026, 11, 5, 12)),
      ];

      final result = sortForDisplay(tasks);

      expect(result.map((t) => t.id).toList(), ['new', 'old']);
    });

    test('пустой список', () {
      expect(sortForDisplay(const <Task>[]), isEmpty);
    });
  });
}
