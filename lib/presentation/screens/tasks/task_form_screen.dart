import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/domain/entities/task.dart';
import 'package:iot_task_manager/presentation/providers/task_provider.dart';
import 'package:uuid/uuid.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskType _type;
  late DateTime _scheduledDate;
  late TaskPriority _priority;
  late String _category;
  late bool _showOnEsp32;
  bool _isLoading = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _type = task?.type ?? TaskType.today;
    _scheduledDate = task?.scheduledDate ?? DateTime.now();
    _priority = task?.priority ?? TaskPriority.medium;
    _category = task?.category ?? 'General';
    _showOnEsp32 = task?.showOnEsp32 ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        await ref.read(taskActionsProvider.notifier).updateTask(
              widget.task!.copyWith(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                type: _type,
                scheduledDate: _scheduledDate,
                priority: _priority,
                category: _category,
                showOnEsp32: _showOnEsp32,
                updatedAt: DateTime.now(),
              ),
            );
      } else {
        await ref.read(taskActionsProvider.notifier).createTask(
              Task(
                id: const Uuid().v4(),
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                type: _type,
                scheduledDate: _scheduledDate,
                priority: _priority,
                category: _category,
                showOnEsp32: _showOnEsp32,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Edit Task' : 'New Task',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _isEditing ? 'Update your task details' : 'Create a new task',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5),
                          ),
                        )
                      : FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Save',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _SectionCard(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Task Title',
                            hintText: 'What needs to be done?',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.edit_rounded,
                                  size: 20, color: AppColors.primary),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Title is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Add more details...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.description_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      children: [
                        _DropdownField<TaskType>(
                          label: 'Task Type',
                          icon: Icons.repeat_rounded,
                          value: _type,
                          items: const [
                            DropdownMenuItem(
                                value: TaskType.today,
                                child: Text('Today')),
                            DropdownMenuItem(
                                value: TaskType.daily,
                                child: Text('Daily')),
                            DropdownMenuItem(
                                value: TaskType.constant,
                                child: Text('Constant')),
                            DropdownMenuItem(
                                value: TaskType.weekly,
                                child: Text('Weekly')),
                            DropdownMenuItem(
                                value: TaskType.monthly,
                                child: Text('Monthly')),
                            DropdownMenuItem(
                                value: TaskType.customDate,
                                child: Text('Custom Date')),
                          ],
                          onChanged: (v) =>
                              setState(() => _type = v!),
                        ),
                        const Divider(height: 24),
                        _DatePickerTile(
                          label: 'Scheduled Date',
                          icon: Icons.calendar_today_rounded,
                          date: _scheduledDate,
                          onChanged: (d) =>
                              setState(() => _scheduledDate = d),
                        ),
                        const Divider(height: 24),
                        _DropdownField<TaskPriority>(
                          label: 'Priority',
                          icon: Icons.flag_rounded,
                          value: _priority,
                          items: const [
                            DropdownMenuItem(
                                value: TaskPriority.critical,
                                child: Text('Critical')),
                            DropdownMenuItem(
                                value: TaskPriority.high,
                                child: Text('High')),
                            DropdownMenuItem(
                                value: TaskPriority.medium,
                                child: Text('Medium')),
                            DropdownMenuItem(
                                value: TaskPriority.low,
                                child: Text('Low')),
                          ],
                          onChanged: (v) =>
                              setState(() => _priority = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      children: [
                        TextFormField(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'e.g. Work, Personal, Health',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.folder_rounded,
                                  size: 20,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          onChanged: (v) => _category = v,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      children: [
                        SwitchListTile(
                          value: _showOnEsp32,
                          onChanged: (v) => setState(() => _showOnEsp32 = v),
                          title: const Text('Show on ESP32',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Display this task on the IoT device',
                              style: TextStyle(fontSize: 12)),
                          secondary: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (_showOnEsp32 ? AppColors.tertiary : AppColors.textSecondary)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _showOnEsp32 ? Icons.developer_board_rounded : Icons.developer_board_outlined,
                              color: _showOnEsp32 ? AppColors.tertiary : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          activeThumbColor: AppColors.tertiary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: children),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Padding(padding: EdgeInsets.only(left: 4), child: Icon(icon, size: 20, color: AppColors.primary)),
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerTile({
    required this.label,
    required this.icon,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                dialogTheme: const DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 16),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_calendar_rounded,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
