import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _textScrollController;
  late final AnimationController _shimmerController;
  late final AnimationController _auroraController;

  // Interaction State
  Offset _dragOffset = Offset.zero;

  // Exit State
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // 1. CARD ORBIT
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 2. TEXT SCROLL
    _textScrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // 3. SLIDER SHIMMER
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 4. AURORA MOVEMENT
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _textScrollController.dispose();
    _shimmerController.dispose();
    _auroraController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Parallax Force
      _dragOffset += details.delta * 0.5;
      _dragOffset = Offset(
        _dragOffset.dx.clamp(-50.0, 50.0),
        _dragOffset.dy.clamp(-50.0, 50.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Optional: Snap back logic could go here
  }

  void _triggerIgnition() async {
    HapticFeedback.heavyImpact();
    setState(() => _isExiting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: ClipRect(
          child: Stack(
            children: [
              // 1. LIVING AURORA BACKGROUND (Clean, no snow)
              _LivingAurora(controller: _auroraController),

              // 2. INFINITE MARQUEE
              Positioned(
                top: 100,
                left: -100,
                right: -100,
                height: 200,
                child: Opacity(
                  opacity: 0.05,
                  child: Transform.rotate(
                    angle: -0.1,
                    child: _InfiniteMarquee(controller: _textScrollController),
                  ),
                ),
              ),

              // 3. CINEMATIC GRAIN OVERLAY
              const Positioned.fill(
                child: Opacity(
                  opacity: 0.03,
                  child: _FilmGrain(),
                ),
              ),

              // 4. MAIN INTERFACE
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // 3D ORBITAL STACK
                    AnimatedScale(
                      scale: _isExiting ? 8.0 : 1.0,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInCirc,
                      child: SizedBox(
                        height: 380, // Slightly taller for info
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _OrbitingCard(
                              controller: _orbitController,
                              dragOffset: _dragOffset,
                              offsetPhase: 0.0,
                              scale: 0.85,
                              child: const _CardContent(
                                icon: CupertinoIcons.scope,
                                title: 'Horizon',
                                subtitle: 'Predictive Engine',
                                description:
                                    'See weeks ahead. Our engine forecasts cashflow gaps before they happen.',
                                color: Colors.purpleAccent,
                              ),
                            ),
                            _OrbitingCard(
                              controller: _orbitController,
                              dragOffset: _dragOffset,
                              offsetPhase: 2.0,
                              scale: 0.92,
                              child: const _CardContent(
                                icon: CupertinoIcons.lock_shield_fill,
                                title: 'Privacy',
                                subtitle: 'Local-First Core',
                                description:
                                    'Your financial data is encrypted on your device. No tracking. No ads.',
                                color: Colors.blueAccent,
                              ),
                            ),
                            _OrbitingCard(
                              controller: _orbitController,
                              dragOffset: _dragOffset,
                              offsetPhase: 4.0,
                              scale: 1.0,
                              isHero: true,
                              child: const _CardContent(
                                icon: CupertinoIcons.hexagon_fill,
                                title: 'VYLT',
                                subtitle: 'Total Liquidity',
                                description:
                                    'Aggregate every account, asset, and liability into one calm, truthful view.',
                                color: Colors.white,
                                isHero: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // 5. DECODING TEXT & SLIDER
                    AnimatedOpacity(
                      opacity: _isExiting ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const _DecodingText(
                              text: 'Wealth Requires\nVision.',
                              style: TextStyle(
                                fontFamily: '.SF Pro Display',
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Stop looking backward.\nStart seeing the horizon.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: '.SF Pro Text',
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 50),
                            _HolographicSlider(
                              shimmerController: _shimmerController,
                              onSlideComplete: _triggerIgnition,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   NEW UPGRADES: AURORA & GRAIN (Clean)
   ============================================================ */

// 1. LIVING AURORA (Moving Background Blobs)
class _LivingAurora extends StatelessWidget {
  final AnimationController controller;
  const _LivingAurora({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Blobs move in organic patterns
        final t = controller.value * 2 * math.pi;

        return Stack(
          children: [
            // Top Left (Purple)
            Positioned(
              top: -100 + (math.sin(t) * 30),
              left: -100 + (math.cos(t) * 30),
              child: _GlowOrb(color: const Color(0xFF4A00E0).withOpacity(0.25)),
            ),
            // Bottom Right (Teal)
            Positioned(
              bottom: -100 + (math.sin(t + 2) * 40),
              right: -100 + (math.cos(t + 1) * 20),
              child: _GlowOrb(color: const Color(0xFF00E5FF).withOpacity(0.2)),
            ),
            // Center (Blue Pulse)
            Positioned(
              top: 300 + (math.sin(t * 0.5) * 50),
              left: -100,
              right: -100,
              child: Center(
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blueAccent
                            .withOpacity(0.05 * (0.5 + 0.5 * math.sin(t))),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// 2. FILM GRAIN (Procedural Texture)
class _FilmGrain extends StatelessWidget {
  const _FilmGrain();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrainPainter(),
      child: Container(),
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1);
    final random = math.Random();

    // Draw random tiny dots for texture
    for (int i = 0; i < 5000; i++) {
      canvas.drawRect(
          Rect.fromLTWH(random.nextDouble() * size.width,
              random.nextDouble() * size.height, 1, 1),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* ============================================================
   CORE UI COMPONENTS
   ============================================================ */

class _OrbitingCard extends StatelessWidget {
  final AnimationController controller;
  final Offset dragOffset;
  final double offsetPhase;
  final double scale;
  final Widget child;
  final bool isHero;

  const _OrbitingCard({
    required this.controller,
    required this.dragOffset,
    required this.offsetPhase,
    required this.scale,
    required this.child,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value * 2 * math.pi) + offsetPhase;

        final orbitX = math.sin(t) * 15;
        final orbitY = math.sin(t * 2) * 10;

        // Parallax Interaction
        final interactX = dragOffset.dx * (1.5 - scale);
        final interactY = dragOffset.dy * (1.5 - scale);

        final totalX = orbitX + interactX;
        final totalY = orbitY + interactY;

        final rotateY = totalX * 0.003;
        final rotateX = -totalY * 0.003;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translate(totalX, totalY)
            ..rotateY(rotateY)
            ..rotateX(rotateX)
            ..scale(scale),
          alignment: Alignment.center,
          child: Container(
            width: 240, // Wider for text
            height: 320, // Taller for text
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: isHero
                      ? const Color(0xFF00E5FF).withOpacity(0.15)
                      : Colors.black.withOpacity(0.5),
                  blurRadius: isHero ? 50 : 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isHero
                        ? const Color(0xFF2C2C2E).withOpacity(0.8)
                        : const Color(0xFF1C1C1E).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isHero
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      child,
                      if (isHero)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description; // Added Description
  final Color color;
  final bool isHero;

  const _CardContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: isHero ? 32 : 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12), // Bottom padding
        ],
      ),
    );
  }
}

class _DecodingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _DecodingText({required this.text, required this.style});

  @override
  State<_DecodingText> createState() => _DecodingTextState();
}

class _DecodingTextState extends State<_DecodingText> {
  String _currentText = "";
  final String _chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890@#%&";

  @override
  void initState() {
    super.initState();
    _startDecoding();
  }

  void _startDecoding() async {
    await Future.delayed(const Duration(milliseconds: 500));
    int length = widget.text.length;
    for (int i = 0; i <= length; i++) {
      if (!mounted) return;
      setState(() {
        _currentText = widget.text.substring(0, i);
        if (i < length) {
          _currentText += _chars[math.Random().nextInt(_chars.length)];
        }
      });
      if (i % 2 == 0) HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentText,
      textAlign: TextAlign.center,
      style: widget.style,
    );
  }
}

class _HolographicSlider extends StatefulWidget {
  final AnimationController shimmerController;
  final VoidCallback onSlideComplete;
  const _HolographicSlider(
      {required this.shimmerController, required this.onSlideComplete});

  @override
  State<_HolographicSlider> createState() => _HolographicSliderState();
}

class _HolographicSliderState extends State<_HolographicSlider> {
  double _dragValue = 0.0;
  final double _maxWidth = 280.0;
  final double _handleSize = 56.0;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragValue = (_dragValue + details.delta.dx)
          .clamp(0.0, _maxWidth - _handleSize - 8);
    });
    if (_dragValue % 10 < 1) HapticFeedback.selectionClick();
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragValue > (_maxWidth - _handleSize) * 0.7) {
      setState(() => _dragValue = _maxWidth - _handleSize - 8);
      widget.onSlideComplete();
    } else {
      setState(() => _dragValue = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _maxWidth,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            width: _dragValue + _handleSize,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.1)
                ],
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: widget.shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [Colors.white38, Colors.white, Colors.white38],
                      stops: [0.0, 0.5, 1.0],
                      transform: GradientRotation(
                          widget.shimmerController.value * 2 * math.pi),
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'Slide to Enter',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 4 + _dragValue,
            top: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Container(
                width: _handleSize,
                height: _handleSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 1)
                  ],
                ),
                child: const Icon(CupertinoIcons.chevron_right,
                    color: Colors.black, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfiniteMarquee extends StatelessWidget {
  final AnimationController controller;
  const _InfiniteMarquee({required this.controller});
  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: double.infinity,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(-controller.value * 1000, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(' CLARITY • INTELLIGENCE • CONTROL • HORIZON • VYLT • ',
                    style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                Text(' CLARITY • INTELLIGENCE • CONTROL • HORIZON • VYLT • ',
                    style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                Text(' CLARITY • INTELLIGENCE • CONTROL • HORIZON • VYLT • ',
                    style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  const _GlowOrb({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, Colors.transparent])));
  }
}