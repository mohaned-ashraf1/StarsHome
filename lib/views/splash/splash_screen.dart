import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/db_service.dart';
import '../../core/services/sync_service.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bgController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _logoController.forward();
    _bgController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // Safely initialize local DB and Sync in parallel with animation
    try {
      await DBService.instance.database;
    } catch (e) {
      debugPrint('DB initialization in splash: $e');
    }

    try {
      await SyncService.instance.init();
    } catch (e) {
      debugPrint('SyncService initialization in splash: $e');
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      _navigateToNext();
    }
  }

  void _navigateToNext() {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Never automatically authenticate — always route unauthenticated users to login
    final destination =
        auth.authState == AuthState.authenticated ? const HomeScreen() : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0F),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0 + (_bgController.value * 0.3),
                    colors: [
                      const Color(0xFF1B4332).withOpacity(0.8),
                      const Color(0xFF0A1A0F),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),
          ..._buildGoldenParticles(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D6A4F).withOpacity(0.6),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFD4AF37),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'STARS HOMES',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD4AF37),
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نظام الإدارة المالية',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'مصنع الأثاث • القاهرة',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF2D6A4F).withOpacity(0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 60,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFD4AF37),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: child,
                );
              },
              child: const Center(
                child: _LoadingDots(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGoldenParticles() {
    final positions = [
      const Alignment(-0.8, -0.7),
      const Alignment(0.7, -0.6),
      const Alignment(-0.5, 0.8),
      const Alignment(0.8, 0.7),
      const Alignment(0.0, -0.9),
      const Alignment(-0.9, 0.1),
    ];

    return positions.map((alignment) {
      return AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Align(
            alignment: alignment,
            child: Opacity(
              opacity: 0.1 + (_bgController.value * 0.15),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _animations = _controllers
        .map(
          (c) => Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(_animations[i].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

