import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final bool darkMode;
  final bool notificationsEnabled;
  final int notificationTime;
  final bool backupEnabled;

  const UserSettings({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.notificationTime = 8,
    this.backupEnabled = false,
  });

  UserSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    int? notificationTime,
    bool? backupEnabled,
  }) {
    return UserSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      backupEnabled: backupEnabled ?? this.backupEnabled,
    );
  }

  @override
  List<Object?> get props =>
      [darkMode, notificationsEnabled, notificationTime, backupEnabled];
}
