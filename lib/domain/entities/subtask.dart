import 'package:meta/meta.dart';

/// A checklist item inside a [Task].
@immutable
class Subtask {
  const Subtask({
    required this.id,
    required this.title,
    this.isDone = false,
    this.sortIndex = 0,
  });

  final String id;
  final String title;
  final bool isDone;
  final int sortIndex;

  Subtask copyWith({String? title, bool? isDone, int? sortIndex}) => Subtask(
    id: id,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
    sortIndex: sortIndex ?? this.sortIndex,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isDone': isDone,
    'sortIndex': sortIndex,
  };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    isDone: json['isDone'] as bool? ?? false,
    sortIndex: json['sortIndex'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subtask &&
          other.id == id &&
          other.title == title &&
          other.isDone == isDone &&
          other.sortIndex == sortIndex;

  @override
  int get hashCode => Object.hash(id, title, isDone, sortIndex);
}
