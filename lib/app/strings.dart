import 'package:flutter/material.dart';

import '../domain/task_validation.dart';

/// Локализация приложения: русский и английский (ТЗ, раздел 6).
///
/// Строки вынесены из кода; даты форматируются по локали устройства.
class Strings {
  Strings(this.locale);

  final Locale locale;

  static Strings of(BuildContext context) =>
      Strings(Localizations.localeOf(context));

  bool get isRu => locale.languageCode.toLowerCase().startsWith('ru');

  // --- Экран «Сегодня» -----------------------------------------------------
  String get todayWord => isRu ? 'Сегодня' : 'Today';
  String get appTitle => isRu ? 'Задачи на день' : 'Day tasks';

  String headerDate(DateTime date) {
    final weekday = isRu
        ? _ruWeekdays[date.weekday - 1]
        : _enWeekdays[date.weekday - 1];
    final month =
        isRu ? _ruMonths[date.month - 1] : _enMonths[date.month - 1];
    return '$weekday, ${date.day} $month';
  }

  String doneCounter(int done, int total) =>
      isRu ? 'Выполнено $done из $total' : '$done of $total done';

  String doneSection(int count) =>
      isRu ? 'Выполненные ($count)' : 'Completed ($count)';

  // --- Пустое состояние и ошибки -----------------------------------------
  String get emptyTitle => isRu ? 'На сегодня задач нет' : 'No tasks for today';
  String get emptyHint =>
      isRu ? 'Добавьте первую задачу внизу' : 'Add your first task below';
  String get loadError => isRu ? 'Не удалось загрузить задачи' : 'Failed to load tasks';
  String get retry => isRu ? 'Повторить' : 'Retry';
  String get storageError => isRu
      ? 'Не удалось сохранить задачу. Попробуйте ещё раз'
      : 'Failed to save the task. Try again';

  // --- Ввод задачи --------------------------------------------------------
  String get inputHint => isRu ? 'Введите задачу…' : 'Enter a task…';
  String get addTooltip => isRu ? 'Добавить задачу' : 'Add task';
  String get emptyInputError =>
      isRu ? 'Введите текст задачи' : 'Enter task text';
  String get maxLengthError =>
      isRu ? 'Максимум ${TitleValidation.maxTitleLength} символов' : 'Maximum ${TitleValidation.maxTitleLength} characters';
  String get limitError => isRu
      ? 'Достигнут дневной лимит задач (${TitleValidation.maxTasksPerDay})'
      : 'Daily task limit reached (${TitleValidation.maxTasksPerDay})';

  // --- Удаление и Undo ----------------------------------------------------
  String get taskDeleted => isRu ? 'Задача удалена' : 'Task deleted';
  String get undo => isRu ? 'Отменить' : 'Undo';
  String get deleteQuestion => isRu ? 'Удалить задачу?' : 'Delete this task?';
  String get deleteAction => isRu ? 'Удалить' : 'Delete';
  String get cancelAction => isRu ? 'Отмена' : 'Cancel';
  String get deleteTooltip => isRu ? 'Удалить задачу' : 'Delete task';

  // --- Тема ---------------------------------------------------------------
  String themeTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return isRu ? 'Тема: светлая' : 'Theme: light';
      case ThemeMode.dark:
        return isRu ? 'Тема: тёмная' : 'Theme: dark';
      case ThemeMode.system:
        return isRu ? 'Тема: системная' : 'Theme: system';
    }
  }

  // --- Доступность --------------------------------------------------------
  String taskSemantics(String title, bool isCompleted) {
    final status = isCompleted
        ? (isRu ? 'выполнена' : 'done')
        : (isRu ? 'не выполнена' : 'not done');
    return isRu ? 'Задача $title, $status' : 'Task $title, $status';
  }

  String get checkboxLabel =>
      isRu ? 'Отметить выполнение' : 'Toggle completion';

  // --- Справочные данные --------------------------------------------------
  static const List<String> _ruWeekdays = <String>[
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];

  static const List<String> _enWeekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _ruMonths = <String>[
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const List<String> _enMonths = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
