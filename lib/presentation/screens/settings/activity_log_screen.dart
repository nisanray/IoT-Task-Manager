import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/core/widgets/animated_list_slot.dart';
import 'package:iot_task_manager/core/widgets/empty_state_widget.dart';
import 'package:iot_task_manager/presentation/providers/activity_log_provider.dart';
import 'package:iot_task_manager/core/utils/date_utils.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Log',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'No activity yet',
              subtitle: 'Your actions will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            physics: const BouncingScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final (icon, color) = _getIcon(log.action);
              return AnimatedListSlot(
                index: index,
                child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF161B22)
                      : Colors.white)
                      .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.white)
                        .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(log.description,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    AppDateUtils.formatDisplayDateTime(log.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  dense: true,
                ),
                  ),
                ),
              ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  (IconData, Color) _getIcon(String action) {
    switch (action) {
      case 'Task Created':
        return (Icons.add_circle_rounded, AppColors.success);
      case 'Task Updated':
        return (Icons.edit_rounded, AppColors.info);
      case 'Task Completed':
        return (Icons.check_circle_rounded, AppColors.success);
      case 'Task Deleted':
        return (Icons.delete_rounded, AppColors.error);
      case 'Task Archived':
        return (Icons.archive_rounded, AppColors.warning);
      case 'Task Restored':
        return (Icons.restore_rounded, AppColors.info);
      case 'Dashboard Regenerated':
        return (Icons.dashboard_rounded, AppColors.primary);
      default:
        return (Icons.info_rounded, AppColors.textSecondary);
    }
  }
}
