import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/presentation/providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  late AnimationController _blobController;
  late AnimationController _formController;
  late Animation<double> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _formSlide = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    _formController.forward();
  }

  @override
  void dispose() {
    _blobController.dispose();
    _formController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final actions = ref.read(authActionsProvider);
      if (_isLogin) {
        await actions.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await actions.signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e));
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0A0E14), const Color(0xFF161B22)]
                    : [const Color(0xFFF0F2F8), const Color(0xFFFFFFFF)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _BlobPainter(
                  animation: _blobController.value,
                  isDark: isDark,
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _formController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _formFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _formSlide.value * 50),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: -5,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.developer_board_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Smart Task Manager',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your IoT tasks effortlessly',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 40),
                        _AuthCard(
                          isLogin: _isLogin,
                          onTabChanged: (login) =>
                              setState(() => _isLogin = login),
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          error: _error,
                          isLoading: _isLoading,
                          onSubmit: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onTabChanged;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? error;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _AuthCard({
    required this.isLogin,
    required this.onTabChanged,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.error,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF161B22) : Colors.white)
            .withValues(alpha: isDark ? 0.7 : 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Sign In',
                  selected: isLogin,
                  onTap: () => onTabChanged(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TabButton(
                  label: 'Sign Up',
                  selected: !isLogin,
                  onTap: () => onTabChanged(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Enter your password' : null,
          ),
          if (!isLogin) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isLogin ? 'Sign In' : 'Create Account',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double animation;
  final bool isDark;

  _BlobPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final blob1Color =
        AppColors.primary.withValues(alpha: isDark ? 0.04 : 0.06);
    final blob2Color =
        AppColors.secondary.withValues(alpha: isDark ? 0.03 : 0.05);

    final path1 = Path();
    final x1 = size.width * 0.3 + sin(animation * 2 * pi) * 30;
    final y1 = size.height * 0.15 + cos(animation * 2 * pi) * 20;
    path1.addOval(Rect.fromCircle(center: Offset(x1, y1), radius: 100));
    paint.color = blob1Color;
    canvas.drawPath(path1, paint);

    final path2 = Path();
    final x2 = size.width * 0.75 + cos(animation * 2 * pi * 0.8) * 25;
    final y2 = size.height * 0.25 + sin(animation * 2 * pi * 0.8) * 15;
    path2.addOval(Rect.fromCircle(center: Offset(x2, y2), radius: 80));
    paint.color = blob2Color;
    canvas.drawPath(path2, paint);

    final path3 = Path();
    final x3 = size.width * 0.5 + sin(animation * 2 * pi * 0.6) * 20;
    final y3 = size.height * 0.85 + cos(animation * 2 * pi * 0.6) * 15;
    path3.addOval(Rect.fromCircle(center: Offset(x3, y3), radius: 90));
    paint.color = blob1Color;
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) =>
      old.animation != animation;
}
