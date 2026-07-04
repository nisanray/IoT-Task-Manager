import 'package:equatable/equatable.dart';

class TaskCategory extends Equatable {
  final String id;
  final String name;
  final int color;
  final int order;
  final DateTime createdAt;

  const TaskCategory({
    required this.id,
    required this.name,
    this.color = 0xFF4F46E5,
    this.order = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, color, order, createdAt];
}
