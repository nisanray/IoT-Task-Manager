import 'package:flutter/material.dart';

class AnimatedListSlot extends StatefulWidget {
  final Widget child;
  final int index;
  final double offset;

  const AnimatedListSlot({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 20,
  });

  @override
  State<AnimatedListSlot> createState() => _AnimatedListSlotState();
}

class _AnimatedListSlotState extends State<AnimatedListSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: Offset(0, 0.03 * widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: FractionalTranslation(
            translation: _slideAnim.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
