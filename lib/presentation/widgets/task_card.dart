import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/domain/entities/task.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onTap;
  final VoidCallback? onToggleEsp32;
  final VoidCallback? onDelete;
  final int index;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onTap,
    this.onToggleEsp32,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isOverdue {
    final now = DateTime.now();
    return widget.task.scheduledDate.isBefore(DateTime(now.year, now.month, now.day)) &&
        !widget.task.completed &&
        !widget.task.deleted &&
        !widget.task.archived;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final priorityColor = switch (widget.task.priority) {
      TaskPriority.critical => AppColors.error,
      TaskPriority.high => AppColors.warning,
      TaskPriority.medium => AppColors.primary,
      TaskPriority.low => colorScheme.outline,
    };

    final priorityGradient = switch (widget.task.priority) {
      TaskPriority.critical => const [AppColors.error, Color(0xFFDC2626)],
      TaskPriority.high => const [AppColors.warning, Color(0xFFD97706)],
      TaskPriority.medium => const [AppColors.primary, AppColors.primaryLight],
      TaskPriority.low => [colorScheme.outline, colorScheme.outline],
    };

    final card = AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: Offset(0.0, (1 - _scaleAnim.value) * 10),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                border: Border.all(
                  color: _isOverdue
                      ? AppColors.error.withValues(alpha: 0.2)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black).withValues(alpha: 0.04),
                  width: _isOverdue ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isOverdue
                        ? AppColors.error.withValues(alpha: 0.06)
                        : AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Material(
                    type: MaterialType.transparency,
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: priorityGradient,
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                              child: Row(
                                children: [
                                  _PremiumCheckbox(
                                    completed: widget.task.completed,
                                    color: priorityColor,
                                    onToggle: widget.onToggleComplete,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                widget.task.title,
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  decoration: widget.task.completed
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  color: widget.task.completed
                                                      ? colorScheme.onSurfaceVariant
                                                      : colorScheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (_isOverdue) ...[
                                              const SizedBox(width: 6),
                                              _OverdueBadge(),
                                            ],
                                          ],
                                        ),
                                        if (widget.task.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.task.description,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _SmallBadge(
                                              text: _typeLabel(widget.task.type),
                                              color: colorScheme.primary.withValues(alpha: 0.1),
                                              textColor: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            _SmallBadge(
                                              text: widget.task.category,
                                              color: colorScheme.secondary.withValues(alpha: 0.1),
                                              textColor: colorScheme.secondary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _Esp32Checkbox(
                                    enabled: widget.task.showOnEsp32,
                                    onToggle: widget.onToggleEsp32,
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: priorityColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.task.priority.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: priorityColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.onDelete == null) return card;

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete!(),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 32),
            title: const Text('Delete Task'),
            content: Text(
              'Are you sure you want to delete "${widget.task.title}"?',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.error),
            const SizedBox(height: 2),
            Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: card,
    );
  }

  String _typeLabel(TaskType type) {
    switch (type) {
      case TaskType.today:
        return 'Today';
      case TaskType.daily:
        return 'Daily';
      case TaskType.constant:
        return 'Constant';
      case TaskType.weekly:
        return 'Weekly';
      case TaskType.monthly:
        return 'Monthly';
      case TaskType.customDate:
        return 'Custom';
    }
  }
}

class _OverdueBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 10, color: AppColors.error),
          const SizedBox(width: 3),
          Text(
            'Overdue',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCheckbox extends StatefulWidget {
  final bool completed;
  final Color color;
  final VoidCallback onToggle;

  const _PremiumCheckbox({
    required this.completed,
    required this.color,
    required this.onToggle,
  });

  @override
  State<_PremiumCheckbox> createState() => _PremiumCheckboxState();
}

class _PremiumCheckboxState extends State<_PremiumCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _checkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.completed) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_PremiumCheckbox old) {
    super.didUpdateWidget(old);
    if (widget.completed != old.completed) {
      if (widget.completed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.completed ? widget.color : Colors.transparent,
                border: Border.all(
                  color: widget.completed
                      ? widget.color
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
                boxShadow: widget.completed
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.completed
                    ? CustomPaint(
                        size: const Size(14, 14),
                        painter: _CheckPainter(
                          progress: _checkAnim.value,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.75);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.progress != progress;
}

class _Esp32Checkbox extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onToggle;

  const _Esp32Checkbox({required this.enabled, this.onToggle});

  @override
  State<_Esp32Checkbox> createState() => _Esp32CheckboxState();
}

class _Esp32CheckboxState extends State<_Esp32Checkbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.enabled) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_Esp32Checkbox old) {
    super.didUpdateWidget(old);
    if (widget.enabled != old.enabled) {
      if (widget.enabled) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? AppColors.tertiary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.enabled
                      ? AppColors.tertiary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  widget.enabled
                      ? Icons.developer_board_rounded
                      : Icons.developer_board_outlined,
                  size: 16,
                  color: widget.enabled
                      ? AppColors.tertiary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _SmallBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class StaggeredTaskList extends StatelessWidget {
  final List<Task> tasks;
  final void Function(Task) onToggleComplete;
  final void Function(Task) onTap;
  final void Function(Task)? onDelete;

  const StaggeredTaskList({
    super.key,
    required this.tasks,
    required this.onToggleComplete,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          index: index,
          onToggleComplete: () => onToggleComplete(task),
          onTap: () => onTap(task),
          onDelete: onDelete != null ? () => onDelete!(task) : null,
        );
      },
    );
  }
}
