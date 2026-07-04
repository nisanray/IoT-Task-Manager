import 'package:equatable/equatable.dart';

class DashboardItem extends Equatable {
  final String id;
  final String text;

  const DashboardItem({required this.id, required this.text});

  @override
  List<Object?> get props => [id, text];
}

class Dashboard extends Equatable {
  final int version;
  final String generatedDate;
  final String generatedAt;
  final String displayMode;
  final int rotationInterval;
  final List<DashboardItem> today;
  final List<DashboardItem> daily;
  final List<DashboardItem> constant;

  const Dashboard({
    this.version = 1,
    required this.generatedDate,
    required this.generatedAt,
    this.displayMode = 'rotate',
    this.rotationInterval = 15,
    this.today = const [],
    this.daily = const [],
    this.constant = const [],
  });

  @override
  List<Object?> get props => [
        version,
        generatedDate,
        generatedAt,
        displayMode,
        rotationInterval,
        today,
        daily,
        constant,
      ];
}
