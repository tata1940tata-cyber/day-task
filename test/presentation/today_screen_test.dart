import 'package:day_task/app/app.dart';
import 'package:day_task/domain/task.dart';
import 'package:day_task/presentation/today/today_controller.dart';
import 'package:day_task/presentation/today/widgets/task_checkbox.dart';
import 'package:day_task/presentation/today/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/in_memory_task_repository.dart';

Widget buildApp(InMemoryTaskRepository repository) {
  return ProviderScope(
    overrides: <Override>[
      taskRepositoryProvider.overrideWithValue(repository),
      settingsStoreProvider.overrideWithValue(repository),
    ],
    child: const DayTaskApp(locale: Locale('ru')),
  );
}

Future<void> addTask(WidgetTester tester, String title) async {
  await tester.enterText(find.byKey(const Key('add_task_field')), title);
  await tester.tap(find.byKey(const Key('add_task_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('показывает пустое состояние (FR-01)', (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();

    expect(find.text('На сегодня задач нет'), findsOneWidget);
    expect(find.text('Добавьте первую задачу внизу'), findsOneWidget);
    expect(find.text('Выполнено 0 из 0'), findsOneWidget);
  });

  testWidgets('добавляет задачу и очищает поле (FR-02)', (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();

    await addTask(tester, 'Купить молоко');

    expect(find.text('Купить молоко'), findsOneWidget);
    expect(find.text('Выполнено 0 из 1'), findsOneWidget);
    final field =
        tester.widget<TextField>(find.byKey(const Key('add_task_field')));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('пустой ввод показывает подсказку (FR-02)', (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_task_button')));
    await tester.pumpAndSettle();

    expect(find.text('Введите текст задачи'), findsOneWidget);
    expect(find.byType(TaskTile), findsNothing);
  });

  testWidgets('отмечает задачу выполненной и снимает отметку (FR-03)',
      (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();
    await addTask(tester, 'Сделать отчёт');

    await tester.tap(find.byType(TaskCheckbox));
    await tester.pumpAndSettle();

    expect(find.text('Выполнено 1 из 1'), findsOneWidget);
    expect(find.text('Выполненные (1)'), findsOneWidget);

    await tester.tap(find.byType(TaskCheckbox));
    await tester.pumpAndSettle();

    expect(find.text('Выполнено 0 из 1'), findsOneWidget);
    expect(find.text('Выполненные (1)'), findsNothing);
  });

  testWidgets('порядок: невыполненные сверху, выполненные под заголовком',
      (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();
    await addTask(tester, 'Первая');
    await addTask(tester, 'Вторая');

    await tester.tap(find.text('Первая'));
    await tester.pumpAndSettle();

    final headerY = tester.getTopLeft(find.text('Выполненные (1)')).dy;
    final firstY = tester.getTopLeft(find.text('Первая')).dy;
    final secondY = tester.getTopLeft(find.text('Вторая')).dy;

    expect(secondY, lessThan(headerY));
    expect(headerY, lessThan(firstY));
  });

  testWidgets('быстрые повторные нажатия учитываются по чёт/нечёт (FR-03)',
      (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();
    await addTask(tester, 'Быстрые тапы');

    // Десять нажатий без перерисовки между ними.
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byType(TaskCheckbox), warnIfMissed: false);
    }
    await tester.pumpAndSettle();

    expect(find.text('Выполнено 0 из 1'), findsOneWidget);

    await tester.tap(find.byType(TaskCheckbox));
    await tester.pumpAndSettle();

    expect(find.text('Выполнено 1 из 1'), findsOneWidget);
  });

  testWidgets('удаляет задачу свайпом и восстанавливает по «Отменить» (FR-04)',
      (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();
    await addTask(tester, 'Убраться');

    await tester.drag(find.byType(TaskTile), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.byType(TaskTile), findsNothing);
    expect(find.text('Задача удалена'), findsOneWidget);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();

    expect(find.text('Убраться'), findsOneWidget);
  });

  testWidgets('удаляет задачу через долгое нажатие с подтверждением (FR-04)',
      (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();
    await addTask(tester, 'Позвонить врачу');

    await tester.longPress(find.byType(TaskTile));
    await tester.pumpAndSettle();
    expect(find.text('Удалить задачу?'), findsOneWidget);

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Позвонить врачу'), findsOneWidget);

    await tester.longPress(find.byType(TaskTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskTile), findsNothing);
    expect(find.text('Задача удалена'), findsOneWidget);
  });

  testWidgets('соблюдает дневной лимит в 100 задач (FR-02)', (tester) async {
    final repository = InMemoryTaskRepository();
    final now = DateTime.now();
    for (var i = 0; i < 100; i++) {
      repository.seed(Task(
        id: 'seed-$i',
        title: 'Задача $i',
        createdAt: now,
        position: i,
      ));
    }
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    await addTask(tester, 'Лишняя');

    expect(find.text('Достигнут дневной лимит задач (100)'), findsOneWidget);
    // Задача не добавлена; текст остаётся только в поле ввода.
    expect(
      find.descendant(
        of: find.byType(TaskTile),
        matching: find.text('Лишняя'),
      ),
      findsNothing,
    );
  });

  testWidgets('сообщение об ошибке хранилища (FR-05)', (tester) async {
    final repository = InMemoryTaskRepository()..failSaves = true;
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    await addTask(tester, 'Не сохранится');

    expect(find.text('Не удалось сохранить задачу. Попробуйте ещё раз'),
        findsWidgets);
  });

  testWidgets('задачи прошлых дней не показываются (FR-01, S3)', (tester) async {
    final repository = InMemoryTaskRepository();
    repository.seed(Task(
      id: 'yesterday',
      title: 'Вчерашняя',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      position: 0,
    ));
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Вчерашняя'), findsNothing);
    expect(find.text('На сегодня задач нет'), findsOneWidget);
  });

  testWidgets('состояние переживает пересоздание приложения (FR-05)',
      (tester) async {
    final repository = InMemoryTaskRepository();
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();
    await addTask(tester, 'Переживёт закрытие');

    // «Убийство» приложения: виджет полностью снимается с дерева.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Переживёт закрытие'), findsOneWidget);
  });

  testWidgets('переключение темы (A10)', (tester) async {
    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme_toggle')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme_toggle')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });

  testWidgets('работает с включённой настройкой «Уменьшить движение» (FR-06)',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(buildApp(InMemoryTaskRepository()));
    await tester.pumpAndSettle();
    await addTask(tester, 'Без анимаций');

    expect(find.text('Без анимаций'), findsOneWidget);
    expect(find.text('Выполнено 0 из 1'), findsOneWidget);
  });

  testWidgets('английская локализация', (tester) async {
    final repository = InMemoryTaskRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        taskRepositoryProvider.overrideWithValue(repository),
        settingsStoreProvider.overrideWithValue(repository),
      ],
      child: const DayTaskApp(locale: Locale('en')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No tasks for today'), findsOneWidget);
    expect(find.text('0 of 0 done'), findsOneWidget);
  });
}
