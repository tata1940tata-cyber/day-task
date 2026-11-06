/// Сущность задачи. Соответствует модели данных из ТЗ (раздел 3.3).
class Task {
  Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.position,
    this.completedAt,
    this.isCompleted = false,
    this.schemaVersion = currentSchemaVersion,
  });

  /// Текущая версия схемы записи (для будущих миграций).
  static const int currentSchemaVersion = 1;

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final int position;
  final int schemaVersion;

  Task copyWith({
    String? title,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
    int? position,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      schemaVersion: schemaVersion,
    );
  }

  /// Отметить задачу выполненной в момент [when].
  Task complete(DateTime when) => copyWith(isCompleted: true, completedAt: when);

  /// Снять отметку о выполнении.
  Task uncomplete() => copyWith(isCompleted: false, clearCompletedAt: true);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'position': position,
      'schemaVersion': schemaVersion,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Task.id отсутствует или имеет неверный формат');
    }
    if (title is! String) {
      throw const FormatException('Task.title отсутствует или имеет неверный формат');
    }
    final createdRaw = json['createdAt'];
    final completedRaw = json['completedAt'];
    final createdAt =
        createdRaw is String ? DateTime.tryParse(createdRaw) : null;
    final completedAt =
        completedRaw is String ? DateTime.tryParse(completedRaw) : null;
    return Task(
      id: id,
      title: title,
      createdAt: createdAt ?? DateTime.now(),
      completedAt: completedAt,
      isCompleted: json['isCompleted'] as bool? ?? completedAt != null,
      position: (json['position'] as num?)?.toInt() ?? 0,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.isCompleted == isCompleted &&
        other.position == position &&
        other.schemaVersion == schemaVersion;
  }

  @override
  int get hashCode => Object.hash(
      id, title, createdAt, completedAt, isCompleted, position, schemaVersion);

  @override
  String toString() =>
      'Task(id: $id, title: $title, isCompleted: $isCompleted, position: $position)';
}
