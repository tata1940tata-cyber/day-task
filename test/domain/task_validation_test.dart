import 'package:day_task/domain/task_validation.dart';
import 'package:flutter_test/flutter_test.dart';

String repeat(String value, int count) => List<String>.filled(count, value).join();

void main() {
  group('TitleValidation', () {
    test('пустой текст — ошибка empty', () {
      expect(TitleValidation.validate(''), TitleValidationError.empty);
    });

    test('текст из пробелов — ошибка empty', () {
      expect(TitleValidation.validate('   \n\t '), TitleValidationError.empty);
    });

    test('нормализация убирает пробелы по краям', () {
      expect(TitleValidation.normalize('  кот  '), 'кот');
      expect(TitleValidation.validate('  кот  '), isNull);
    });

    test('200 символов — допустимо', () {
      expect(TitleValidation.validate(repeat('а', 200)), isNull);
    });

    test('201 символ — ошибка tooLong', () {
      expect(TitleValidation.validate(repeat('а', 201)), TitleValidationError.tooLong);
    });

    test('эмодзи считаются по графемам', () {
      expect(TitleValidation.validate(repeat('👍', 200)), isNull);
      expect(
        TitleValidation.validate(repeat('👍', 201)),
        TitleValidationError.tooLong,
      );
    });

    test('лимит задач в день — 100, максимум текста — 200', () {
      expect(TitleValidation.maxTasksPerDay, 100);
      expect(TitleValidation.maxTitleLength, 200);
    });
  });
}
