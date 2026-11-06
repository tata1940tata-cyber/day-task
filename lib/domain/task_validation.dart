import 'package:characters/characters.dart';

/// Ошибки валидации текста задачи (ТЗ, раздел 3.3).
enum TitleValidationError { empty, tooLong, limitReached }

/// Валидация и нормализация текста задачи.
abstract final class TitleValidation {
  /// Максимум 200 символов (по графемам) — ТЗ, FR-02.
  static const int maxTitleLength = 200;

  /// Максимум 100 задач в день — ТЗ, FR-02.
  static const int maxTasksPerDay = 100;

  /// Убрать пробелы по краям.
  static String normalize(String raw) => raw.trim();

  /// Проверить ввод. Возвращает `null`, если ввод корректен.
  static TitleValidationError? validate(String raw) {
    final text = normalize(raw);
    if (text.isEmpty) return TitleValidationError.empty;
    if (text.characters.length > maxTitleLength) {
      return TitleValidationError.tooLong;
    }
    return null;
  }
}
