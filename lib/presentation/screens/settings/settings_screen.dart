import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/core/widgets/animated_list_slot.dart';
import 'package:iot_task_manager/presentation/screens/backup/backup_screen.dart';
import 'package:iot_task_manager/presentation/screens/categories/categories_screen.dart';
import 'package:iot_task_manager/presentation/screens/settings/activity_log_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 8),
              child: Text('Settings',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              child: Column(
                children: [
                  AnimatedListSlot(
                    index: 0,
                    child: _SettingsCard(
                    items: [
                      _SettingItem(
                        icon: Icons.category_rounded,
                        iconColor: AppColors.primary,
                        title: 'Categories',
                        subtitle: 'Manage task categories',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CategoriesScreen()),
                        ),
                      ),
                      _SettingItem(
                        icon: Icons.history_rounded,
                        iconColor: AppColors.secondary,
                        title: 'Activity Log',
                        subtitle: 'View recent activity',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ActivityLogScreen()),
                        ),
                      ),
                      _SettingItem(
                        icon: Icons.backup_rounded,
                        iconColor: AppColors.info,
                        title: 'Backup & Restore',
                        subtitle: 'Export or import your data',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const BackupScreen()),
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedListSlot(
                    index: 1,
                    child: _SettingsCard(
                    items: [
                      _SettingItem(
                        icon: Icons.palette_rounded,
                        iconColor: AppColors.tertiary,
                        title: 'Theme',
                        subtitle: 'Follow system settings',
                        trailing: Switch(
                          value: false,
                          onChanged: (_) {},
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                      _SettingItem(
                        icon: Icons.notifications_rounded,
                        iconColor: AppColors.warning,
                        title: 'Notifications',
                        subtitle: 'Receive task reminders',
                        trailing: Switch(
                          value: true,
                          onChanged: (_) {},
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedListSlot(
                    index: 2,
                    child: Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.info_rounded,
                              color: AppColors.textSecondary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Smart Task Manager',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                              Text('Version 1.0.0',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: theme.colorScheme
                                              .onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingItem> items;

  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (isDark ? const Color(0xFF161B22) : Colors.white)
            .withValues(alpha: isDark ? 0.5 : 0.6),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.08 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
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
            children: items.asMap().entries.map((entry) {
              return Column(
                children: [
                  if (entry.key > 0)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: isDark ? 0.08 : 0.06),
                    ),
                  entry.value,
                ],
              );
            }).toList(),
          ),
        ),
      ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
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
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
