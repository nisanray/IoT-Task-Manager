import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/firebase_options.dart';
import 'package:iot_task_manager/presentation/providers/auth_provider.dart';
import 'package:iot_task_manager/presentation/screens/auth/auth_screen.dart';
import 'package:iot_task_manager/presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: SmartTaskManagerApp()));
}

class SmartTaskManagerApp extends ConsumerWidget {
  const SmartTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Smart Task Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : const AuthScreen(),
        loading: () => const _SplashScreen(),
        error: (_, _) => const AuthScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _pulseScale;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _logoController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A0E14), const Color(0xFF161B22)]
                : [const Color(0xFFF0F2F8), const Color(0xFFFFFFFF)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnim,
          builder: (context, _) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Stack(
                children: [
                  Positioned(
                    top: -80,
                    right: -60,
                    child: _GlowOrb(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.12),
                      size: 200,
                      pulseAnim: _pulseScale,
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -60,
                    child: _GlowOrb(
                      color: AppColors.secondary.withValues(alpha: isDark ? 0.06 : 0.1),
                      size: 160,
                      pulseAnim: _pulseScale,
                    ),
                  ),
                  Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_logoController, _pulseController]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value * _pulseScale.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryLight],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 40,
                                        spreadRadius: -8,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.developer_board_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Smart Task',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                ),
                                Text(
                                  'Manager',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: -0.5,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final Animation<double> pulseAnim;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnim.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        );
      },
    );
  }
}
