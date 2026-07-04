import 'package:iot_task_manager/domain/entities/dashboard.dart';

class DashboardItemModel {
  final String id;
  final String text;

  const DashboardItemModel({required this.id, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory DashboardItemModel.fromJson(Map<String, dynamic> json) {
    return DashboardItemModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  DashboardItem toEntity() => DashboardItem(id: id, text: text);

  factory DashboardItemModel.fromEntity(DashboardItem item) =>
      DashboardItemModel(id: item.id, text: item.text);
}

class DashboardModel {
  final int version;
  final String generatedDate;
  final String generatedAt;
  final String displayMode;
  final int rotationInterval;
  final List<DashboardItemModel> today;
  final List<DashboardItemModel> daily;
  final List<DashboardItemModel> constant;

  const DashboardModel({
    this.version = 1,
    required this.generatedDate,
    required this.generatedAt,
    this.displayMode = 'rotate',
    this.rotationInterval = 15,
    this.today = const [],
    this.daily = const [],
    this.constant = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'generatedDate': generatedDate,
      'generatedAt': generatedAt,
      'displayMode': displayMode,
      'rotationInterval': rotationInterval,
      'today': today.map((e) => e.toJson()).toList(),
      'daily': daily.map((e) => e.toJson()).toList(),
      'constant': constant.map((e) => e.toJson()).toList(),
    };
  }

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      version: json['version'] as int? ?? 1,
      generatedDate: json['generatedDate'] as String? ?? '',
      generatedAt: json['generatedAt'] as String? ?? '',
      displayMode: json['displayMode'] as String? ?? 'rotate',
      rotationInterval: json['rotationInterval'] as int? ?? 15,
      today: (json['today'] as List<dynamic>?)
              ?.map((e) =>
                  DashboardItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      daily: (json['daily'] as List<dynamic>?)
              ?.map((e) =>
                  DashboardItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      constant: (json['constant'] as List<dynamic>?)
              ?.map((e) =>
                  DashboardItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Dashboard toEntity() {
    return Dashboard(
      version: version,
      generatedDate: generatedDate,
      generatedAt: generatedAt,
      displayMode: displayMode,
      rotationInterval: rotationInterval,
      today: today.map((e) => e.toEntity()).toList(),
      daily: daily.map((e) => e.toEntity()).toList(),
      constant: constant.map((e) => e.toEntity()).toList(),
    );
  }

  factory DashboardModel.fromEntity(Dashboard dashboard) {
    return DashboardModel(
      version: dashboard.version,
      generatedDate: dashboard.generatedDate,
      generatedAt: dashboard.generatedAt,
      displayMode: dashboard.displayMode,
      rotationInterval: dashboard.rotationInterval,
      today: dashboard.today
          .map((e) => DashboardItemModel.fromEntity(e))
          .toList(),
      daily: dashboard.daily
          .map((e) => DashboardItemModel.fromEntity(e))
          .toList(),
      constant: dashboard.constant
          .map((e) => DashboardItemModel.fromEntity(e))
          .toList(),
    );
  }
}
