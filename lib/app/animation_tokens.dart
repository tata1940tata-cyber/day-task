import 'package:flutter/animation.dart';

/// Токены анимаций (ТЗ, FR-06). Все длительности и кривые — здесь.
abstract final class T {
  // Длительности (спецификация FR-06, таблица A1–A12).
  static const Duration appear = Duration(milliseconds: 250); // A1, A8
  static const Duration checkbox = Duration(milliseconds: 200); // A2
  static const Duration strikethrough = Duration(milliseconds: 200); // A3
  static const Duration move = Duration(milliseconds: 300); // A4, A5
  static const Duration dismiss = Duration(milliseconds: 250); // A6
  static const Duration settleBack = Duration(milliseconds: 200); // A7
  static const Duration theme = Duration(milliseconds: 300); // A10
  static const Duration sheet = Duration(milliseconds: 300); // A11
  static const Duration shake = Duration(milliseconds: 300); // A12

  /// A9: каскадное появление списка (шаг 30 мс, максимум 8 карточек).
  static const Duration staggerStep = Duration(milliseconds: 30);
  static const Duration staggerItem = Duration(milliseconds: 150);
  static const int staggerMaxItems = 8;

  /// Скрытие snackbar с Undo (FR-04).
  static const Duration undoWindow = Duration(seconds: 5);

  // Кривые.
  static const Curve appearCurve = Curves.easeOutCubic;
  static const Curve checkboxCurve = Curves.easeInOut;
  static const Curve strikeCurve = Curves.easeOut;
  static const Curve moveCurve = Curves.easeInOutCubic;
  static const Curve dismissCurve = Curves.easeInCubic;
  static const Curve settleBackCurve = Curves.easeOut;
  static const Curve themeCurve = Curves.easeInOut;
  static const Curve shakeCurve = Curves.easeInOut;
  static const Curve staggerCurve = Curves.easeOut;

  /// Максимальный «отскок» карточки при возврате, px (A7).
  static const double maxOvershootPx = 4;

  /// При включённой настройке «Уменьшить движение» анимации мгновенны.
  static Duration duration(Duration value, {required bool reducedMotion}) =>
      reducedMotion ? const Duration(milliseconds: 1) : value;
}
