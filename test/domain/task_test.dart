import 'package:day_task/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task', () {
    Task buildTask({
      String id = 'id-1',
      String title = 'Купить продукты',
      bool isCompleted = false,
      DateTime? completedAt,
      int position = 0,
    }) {
      return Task(
        id: id,
        title: title,
        createdAt: DateTime.utc(2026, 11, 5, 8, 15),
        completedAt: completedAt,
        isCompleted: isCompleted,
        position: position,
      );
    }

    test('toJson/fromJson сохраняют все поля', () {
      final task = buildTask(
        isCompleted: true,
        completedAt: DateTime.utc(2026, 11, 5, 10, 2),
        position: 3,
      );

      final restored = Task.fromJson(task.toJson());

      expect(restored, task);
      expect(restored.id, 'id-1');
      expect(restored.title, 'Купить продукты');
      expect(restored.createdAt, DateTime.utc(2026, 11, 5, 8, 15));
      expect(restored.completedAt, DateTime.utc(2026, 11, 5, 10, 2));
      expect(restored.isCompleted, isTrue);
      expect(restored.position, 3);
      expect(restored.schemaVersion, Task.currentSchemaVersion);
    });

    test('fromJson без completedAt и isCompleted выводит статус из даты', () {
      final restored = Task.fromJson(<String, dynamic>{
        'id': 'id-2',
        'title': 'Позвонить врачу',
        'createdAt': '2026-11-05T09:00:00.000Z',
      });

      expect(restored.isCompleted, isFalse);
      expect(restored.completedAt, isNull);
      expect(restored.position, 0);
    });

    test('fromJson без id выбрасывает FormatException', () {
      expect(
        () => Task.fromJson(<String, dynamic>{'title': 'X'}),
        throwsFormatException,
      );
    });

    test('fromJson без title выбрасывает FormatException', () {
      expect(
        () => Task.fromJson(<String, dynamic>{'id': 'x'}),
        throwsFormatException,
      );
    });

    test('complete и uncomplete переключают статус', () {
      final task = buildTask();
      final when = DateTime.utc(2026, 11, 5, 12);

      final completed = task.complete(when);
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, when);

      final uncompleted = completed.uncomplete();
      expect(uncompleted.isCompleted, isFalse);
      expect(uncompleted.completedAt, isNull);
    });

    test('copyWith сохраняет неизменённые поля', () {
      final task = buildTask(position: 7);
      final renamed = task.copyWith(title: 'Новое имя');

      expect(renamed.id, task.id);
      expect(renamed.position, 7);
      expect(renamed.title, 'Новое имя');
    });
  });
}
