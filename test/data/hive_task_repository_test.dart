import 'dart:io';

import 'package:day_task/data/hive_task_repository.dart';
import 'package:day_task/domain/task.dart';
import 'package:day_task/domain/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  Task buildTask({String id = 'id-1', bool done = false}) {
    return Task(
      id: id,
      title: 'Задача $id',
      createdAt: DateTime(2026, 11, 5, 9),
      completedAt: done ? DateTime(2026, 11, 5, 10) : null,
      isCompleted: done,
      position: 0,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('day_task_hive_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveTaskRepository', () {
    test('сохраняет и загружает задачи', () async {
      final repository = await HiveTaskRepository.openBoxes();

      await repository.saveTask(buildTask(id: 'a'));
      await repository.saveTask(buildTask(id: 'b', done: true));

      final tasks = await repository.loadTasks();

      expect(tasks.map((t) => t.id).toSet(), {'a', 'b'});
      expect(tasks.singleWhere((t) => t.id == 'b').isCompleted, isTrue);
    });

    test('данные переживают переоткрытие хранилища (FR-05)', () async {
      final repository = await HiveTaskRepository.openBoxes();
      await repository.saveTask(buildTask(id: 'persisted'));
      await Hive.close();

      Hive.init(tempDir.path);
      final reopened = await HiveTaskRepository.openBoxes();
      final tasks = await reopened.loadTasks();

      expect(tasks.single.id, 'persisted');
    });

    test('удаляет задачу', () async {
      final repository = await HiveTaskRepository.openBoxes();
      await repository.saveTask(buildTask(id: 'gone'));

      await repository.deleteTask('gone');

      expect(await repository.loadTasks(), isEmpty);
    });

    test('обновление статуса сохраняется', () async {
      final repository = await HiveTaskRepository.openBoxes();
      final task = buildTask(id: 'toggle');
      await repository.saveTask(task);

      await repository.saveTask(task.complete(DateTime(2026, 11, 5, 12)));

      final restored = (await repository.loadTasks()).single;
      expect(restored.isCompleted, isTrue);
      expect(restored.completedAt, DateTime(2026, 11, 5, 12));
    });

    test('повреждённые записи пропускаются, данные не теряются', () async {
      final repository = await HiveTaskRepository.openBoxes();
      final box = await Hive.openBox(HiveTaskRepository.tasksBoxName);
      await box.put('broken', <String, dynamic>{'title': 'без id'});
      await box.put('not-a-map', 'мусор');
      await repository.saveTask(buildTask(id: 'good'));

      final tasks = await repository.loadTasks();

      expect(tasks.single.id, 'good');
    });

    test('режим только для чтения при более новой схеме (ТЗ, 3.4)', () async {
      final meta = await Hive.openBox(HiveTaskRepository.metaBoxName);
      await meta.put('schemaVersion', 99);

      final repository = await HiveTaskRepository.openBoxes();

      await expectLater(
        repository.saveTask(buildTask()),
        throwsA(isA<StorageException>()),
      );
      expect(await repository.loadTasks(), isEmpty);
    });

    test('настройки читаются и сохраняются', () async {
      final repository = await HiveTaskRepository.openBoxes();

      await repository.write('themeMode', 'dark');

      expect(repository.read('themeMode'), 'dark');
      expect(repository.read('unknown'), isNull);
    });
  });
}
