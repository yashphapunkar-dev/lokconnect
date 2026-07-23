import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lokconnect/features/login/ui/login.dart';
import 'package:lokconnect/theme/app_palette.dart'; // adjust import path to match your project

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance; // monogram scale/fade in
  late final AnimationController _pulse; // looping ring pulse + rotation

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    Future.delayed(const Duration(milliseconds: 2000), _goToLogin);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: const Login()),
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final scaleCurve = CurvedAnimation(parent: _entrance, curve: Curves.elasticOut);
    final fadeCurve = CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    final textFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    final textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(textFade);

    return Scaffold(
      backgroundColor: palette.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_entrance, _pulse]),
              builder: (context, child) {
                return Transform.scale(
                  scale: scaleCurve.value,
                  child: FadeTransition(
                    opacity: fadeCurve,
                    child: SizedBox(
                      height: 150,
                      width: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Slowly rotating dashed-look ring
                          Transform.rotate(
                            angle: _pulse.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(150, 150),
                              painter: _RingPainter(color: palette.gold.withOpacity(0.35)),
                            ),
                          ),
                          // Breathing glow behind the monogram
                          Container(
                            height: 108 + 8 * math.sin(_pulse.value * 2 * math.pi),
                            width: 108 + 8 * math.sin(_pulse.value * 2 * math.pi),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [palette.gold.withOpacity(0.22), Colors.transparent],
                              ),
                            ),
                          ),
                          // Monogram badge
                          Container(
                            height: 96,
                            width: 96,
                            decoration: BoxDecoration(
                              color: palette.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.gold, width: 1.6),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.gold.withOpacity(0.25),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "LK",
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  color: palette.gold,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 26),
            FadeTransition(
              opacity: textFade,
              child: SlideTransition(
                position: textSlide,
                child: Column(
                  children: [
                    Text(
                      "LokConnect",
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: palette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "LOKMANYA NAGAR, INDORE",
                      style: TextStyle(color: palette.textMuted, fontSize: 11, letterSpacing: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Simple dashed-look ring drawn around the monogram
// ─────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final Color color;
  const _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashCount = 24;
    const gapFraction = 0.5; // half dash, half gap

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      final sweep = (2 * math.pi / dashCount) * gapFraction;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.color != color;
}