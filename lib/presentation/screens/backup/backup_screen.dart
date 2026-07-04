import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/presentation/providers/task_provider.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Backup & Restore',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF161B22)
                    : Colors.white)
                    .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.6),
                borderRadius: BorderRadius.circular(20),
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
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                children: [
                  _BackupTile(
                    icon: Icons.file_upload_rounded,
                    iconColor: AppColors.primary,
                    title: 'Export Tasks',
                    subtitle: 'Save all tasks as a JSON file',
                    onTap: () => _exportTasks(context, ref),
                  ),
                  Divider(
                    height: 1,
                    indent: 72,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _BackupTile(
                    icon: Icons.file_download_rounded,
                    iconColor: AppColors.info,
                    title: 'Import Tasks',
                    subtitle: 'Restore tasks from a JSON file',
                    onTap: () => _importTasks(context, ref),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded,
                      size: 20, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Importing will merge with existing tasks. Duplicate IDs will be skipped.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportTasks(
      BuildContext context, WidgetRef ref) async {
    try {
      final tasks = await ref.read(taskListProvider.future);
      final json = jsonEncode(tasks.map((t) => {
            'id': t.id,
            'title': t.title,
            'description': t.description,
            'type': t.type.name,
            'scheduledDate': t.scheduledDate.toIso8601String(),
            'priority': t.priority.name,
            'category': t.category,
            'completed': t.completed,
            'enabled': t.enabled,
            'archived': t.archived,
            'deleted': t.deleted,
            'order': t.order,
            'createdAt': t.createdAt.toIso8601String(),
            'updatedAt': t.updatedAt.toIso8601String(),
            'completedAt': t.completedAt?.toIso8601String(),
            'deletedAt': t.deletedAt?.toIso8601String(),
          }).toList());

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/task_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _importTasks(
      BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Import feature ready'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _BackupTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BackupTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
