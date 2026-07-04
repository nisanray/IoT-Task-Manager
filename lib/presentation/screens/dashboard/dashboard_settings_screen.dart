import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/core/widgets/animated_list_slot.dart';
import 'package:iot_task_manager/domain/entities/dashboard.dart';
import 'package:iot_task_manager/domain/entities/dashboard_settings.dart';
import 'package:iot_task_manager/presentation/providers/dashboard_provider.dart';

class DashboardSettingsScreen extends ConsumerWidget {
  const DashboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final settingsAsync = ref.watch(dashboardSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Display Settings',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          settingsAsync.when(
            data: (settings) => SliverPadding(
              padding: const EdgeInsets.only(bottom: 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnimatedListSlot(index: 0, child: _buildCard(
                    context,
                    'Sections',
                    Icons.view_quilt_rounded,
                    [
                      _buildSwitch(context, 'Today\'s Tasks',
                          settings.showTodayTasks, (v) {
                        _updateSetting(ref,
                            settings.copyWith(showTodayTasks: v));
                      }),
                      _buildSwitch(context, 'Daily Tasks',
                          settings.showDailyTasks, (v) {
                        _updateSetting(ref,
                            settings.copyWith(showDailyTasks: v));
                      }),
                      _buildSwitch(context, 'Constant Tasks',
                          settings.showConstantTasks, (v) {
                        _updateSetting(ref,
                            settings.copyWith(showConstantTasks: v));
                      }),
                      _buildSwitch(context, 'Weekly Tasks',
                          settings.showWeeklyTasks, (v) {
                        _updateSetting(ref,
                            settings.copyWith(showWeeklyTasks: v));
                      }),
                      _buildSwitch(context, 'Monthly Tasks',
                          settings.showMonthlyTasks, (v) {
                        _updateSetting(ref,
                            settings.copyWith(showMonthlyTasks: v));
                      }),
                    ],
                  ),),
                  const SizedBox(height: 12),
                  AnimatedListSlot(index: 1, child: _buildCard(
                    context,
                    'Display Mode',
                    Icons.slideshow_rounded,
                    [
                      _buildDropdown(
                        context,
                        settings.displayMode,
                        ['today', 'daily', 'constant', 'rotate'],
                        (v) => _updateSetting(
                            ref, settings.copyWith(displayMode: v)),
                      ),
                    ],
                  ),),
                  const SizedBox(height: 12),
                  AnimatedListSlot(index: 2, child: _buildCard(
                    context,
                    'Rotation',
                    Icons.timer_rounded,
                    [
                      _buildSlider(
                        context,
                        'Interval: ${settings.rotationInterval}s',
                        settings.rotationInterval.toDouble(),
                        5, 60, 11,
                        (v) => _updateSetting(ref,
                            settings.copyWith(rotationInterval: v.toInt())),
                      ),
                    ],
                  ),),
                  const SizedBox(height: 12),
                  AnimatedListSlot(index: 3, child: _buildCard(
                    context,
                    'Capacity',
                    Icons.format_list_numbered_rounded,
                    [
                      _buildSlider(
                        context,
                        'Max: ${settings.maxTasksPerSection} tasks',
                        settings.maxTasksPerSection.toDouble(),
                        5, 50, 9,
                        (v) => _updateSetting(ref,
                            settings.copyWith(maxTasksPerSection: v.toInt())),
                      ),
                    ],
                  ),),
                  const SizedBox(height: 12),
                  AnimatedListSlot(index: 4, child: _buildCard(
                    context,
                    'Sort Order',
                    Icons.sort_rounded,
                    [
                      _buildDropdown(
                        context,
                        settings.sortOrder,
                        ['priority', 'date', 'order', 'title'],
                        (v) => _updateSetting(
                            ref, settings.copyWith(sortOrder: v)),
                      ),
                    ],
                  ),),
                  const SizedBox(height: 12),
                  AnimatedListSlot(index: 5, child: _buildCard(
                    context,
                    'Appearance',
                    Icons.palette_rounded,
                    [
                      _buildSwitch(context, 'Compact Mode',
                          settings.compactMode, (v) {
                        _updateSetting(
                            ref, settings.copyWith(compactMode: v));
                      }),
                      _buildSwitch(context, 'Large Text Mode',
                          settings.largeTextMode, (v) {
                        _updateSetting(
                            ref, settings.copyWith(largeTextMode: v));
                      }),
                    ],
                  ),),
                  if (dashboardAsync is AsyncData &&
                      dashboardAsync.value != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _DashboardPreview(
                          dashboard: dashboardAsync.value!),
                    ),
                ]),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, String title, IconData icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(BuildContext context, String title, bool value,
      Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildDropdown(BuildContext context, String value,
      List<String> options, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: options
          .map((o) => DropdownMenuItem(
              value: o,
              child: Text(o[0].toUpperCase() + o.substring(1))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }

  Widget _buildSlider(BuildContext context, String label, double value,
      double min, double max, int divisions, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _updateSetting(WidgetRef ref, DashboardSettings settings) {
    ref
        .read(dashboardSettingsActionsProvider.notifier)
        .updateSettings(settings);
  }
}

class _DashboardPreview extends StatelessWidget {
  final Dashboard dashboard;

  const _DashboardPreview({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Dashboard Preview',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _previewRow(
              context, 'Today', dashboard.today.length, AppColors.primary),
          const SizedBox(height: 6),
          _previewRow(context, 'Daily', dashboard.daily.length,
              AppColors.success),
          const SizedBox(height: 6),
          _previewRow(context, 'Constant', dashboard.constant.length,
              AppColors.warning),
          const SizedBox(height: 12),
          Text('Generated: ${dashboard.generatedDate}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _previewRow(
      BuildContext context, String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
        ),
      ],
    );
  }
}
