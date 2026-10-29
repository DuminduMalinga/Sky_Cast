import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/city_store.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import 'city_search_screen.dart';
import 'home_screen.dart';

const _midnight = Color(0xFF101B36);
const _background = Color(0xFF0B1220);
const _blue = Color(0xFF63B8FF);
const _white = Color(0xFFF4F8FF);
const _muted = Color(0xFF9AABC5);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.service, this.location, super.key});

  final WeatherService? service;
  final LocationService? location;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _showWelcome = true);
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 650),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeIn,
    child: _showWelcome
        ? WelcomeScreen(
            service: widget.service,
            location: widget.location,
            key: const ValueKey('welcome'),
          )
        : _SplashView(animation: _animation, key: const ValueKey('splash')),
  );
}

class _SplashView extends StatelessWidget {
  const _SplashView({required this.animation, super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_midnight, _background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const _Atmosphere(),
            Center(
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkyCastLogo(size: 128, animation: animation.value),
                    const SizedBox(height: 27),
                    const Text(
                      'SkyCast',
                      style: TextStyle(
                        color: _white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your world, in every forecast.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 42,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) =>
                    _LoadingIndicator(progress: animation.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({this.service, this.location, super.key});

  final WeatherService? service;
  final LocationService? location;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _locating = false;

  void _openDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            WeatherHomePage(service: widget.service, location: widget.location),
      ),
    );
  }

  Future<void> _continueWithLocation() async {
    setState(() => _locating = true);
    try {
      await (widget.location ?? LocationService()).currentQuery();
      await AppSettings.instance.setAutoLocation(true);
      if (mounted) _openDashboard();
    } on LocationException catch (error) {
      await AppSettings.instance.setAutoLocation(false);
      if (!mounted) return;
      setState(() => _locating = false);
      // Whatever the reason, don't strand the user: explain it, then let
      // them pick a city by hand.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      await _showManualSearchPrompt();
    }
  }

  Future<void> _showManualSearchPrompt() async {
    final city = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => CitySearchScreen(service: widget.service),
      ),
    );
    if (!mounted) return;
    if (city != null) {
      final store = CityStore();
      await store.saveCurrent(city);
      await store.addRecent(city);
      if (mounted) _openDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_midnight, _background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 42,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _WelcomeHeader(),
                    const SizedBox(height: 18),
                    const _WeatherIllustration(),
                    const SizedBox(height: 24),
                    const Text(
                      'Feel the Weather.\nPlan Your World.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _white,
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _Quote(),
                    const SizedBox(height: 14),
                    const Text(
                      'Discover real-time weather, explore upcoming forecasts, and make every day count.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _openDashboard,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: _background,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Explore Weather'),
                    ),
                    TextButton(
                      onPressed: _locating ? null : _continueWithLocation,
                      style: TextButton.styleFrom(
                        foregroundColor: _white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _locating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Continue with Location',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your location is used only to personalize your forecast.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF71829E), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SkyCastLogo(size: 44),
      const SizedBox(width: 11),
      const Text(
        'SkyCast',
        style: TextStyle(
          color: _white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: .09)),
        ),
        child: const Text(
          'LIVE INTELLIGENCE',
          style: TextStyle(
            color: _blue,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
      ),
    ],
  );
}

class SkyCastLogo extends StatelessWidget {
  const SkyCastLogo({this.size = 96, this.animation = 0, super.key});

  final double size;
  final double animation;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _LogoPainter(animation)),
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.animation);

  final double animation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.width * .25;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF253C67), Color(0xFF162747)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final center = Offset(size.width * .5, size.height * .48);
    final orbit = Paint()
      ..color = _blue.withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .018;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animation * math.pi * 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * .72,
        height: size.width * .36,
      ),
      orbit,
    );
    canvas.restore();
    final sun = Paint()
      ..color = const Color(0xFFFFD98A)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * .06);
    canvas.drawCircle(
      Offset(size.width * .6, size.height * .38),
      size.width * .17,
      sun,
    );
    canvas.drawCircle(
      Offset(size.width * .6, size.height * .38),
      size.width * .12,
      Paint()..color = const Color(0xFFFFD98A),
    );
    final cloud = Paint()..color = _white;
    final cloudPath = Path()
      ..moveTo(size.width * .2, size.height * .65)
      ..cubicTo(
        size.width * .2,
        size.height * .48,
        size.width * .34,
        size.height * .42,
        size.width * .44,
        size.height * .51,
      )
      ..cubicTo(
        size.width * .52,
        size.height * .33,
        size.width * .78,
        size.height * .4,
        size.width * .78,
        size.height * .59,
      )
      ..cubicTo(
        size.width * .9,
        size.height * .58,
        size.width * .9,
        size.height * .78,
        size.width * .72,
        size.height * .8,
      )
      ..lineTo(size.width * .3, size.height * .8)
      ..cubicTo(
        size.width * .12,
        size.height * .8,
        size.width * .1,
        size.height * .66,
        size.width * .2,
        size.height * .65,
      );
    canvas.drawPath(cloudPath, cloud);
    final sparkle = Paint()..color = _blue;
    final sparkleCenter = Offset(size.width * .81, size.height * .25);
    canvas.drawCircle(sparkleCenter, size.width * .035, sparkle);
    canvas.drawLine(
      sparkleCenter.translate(-size.width * .1, 0),
      sparkleCenter.translate(size.width * .1, 0),
      sparkle,
    );
    canvas.drawLine(
      sparkleCenter.translate(0, -size.width * .1),
      sparkleCenter.translate(0, size.width * .1),
      sparkle,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        Positioned(
          top: -150,
          right: -80,
          child: Container(
            width: 390,
            height: 390,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _blue.withValues(alpha: .12),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        const Positioned(top: 125, left: 30, child: _Particle(size: 3)),
        const Positioned(top: 235, right: 38, child: _Particle(size: 2)),
        const Positioned(bottom: 220, left: 54, child: _Particle(size: 2)),
        const Positioned(bottom: 150, right: 78, child: _Particle(size: 3)),
      ],
    ),
  );
}

class _Particle extends StatelessWidget {
  const _Particle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _blue,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: _blue.withValues(alpha: .8), blurRadius: 8)],
    ),
  );
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: 48,
        child: LinearProgressIndicator(
          value: (math.sin(progress * math.pi * 2) + 1) / 2,
          minHeight: 2,
          backgroundColor: Colors.white.withValues(alpha: .1),
          color: _blue,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'READING THE SKY',
        style: TextStyle(
          color: Color(0xFF71829E),
          fontSize: 9,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _WeatherIllustration extends StatelessWidget {
  const _WeatherIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 230,
    child: CustomPaint(
      painter: _WeatherIllustrationPainter(),
      child: const SizedBox.expand(),
    ),
  );
}

class _WeatherIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .48);
    final glow = Paint()
      ..color = const Color(0xFFFFD98A).withValues(alpha: .35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(size.width * .62, size.height * .34), 62, glow);
    canvas.drawCircle(
      Offset(size.width * .62, size.height * .34),
      42,
      Paint()..color = const Color(0xFFFFD98A),
    );
    final ring = Paint()
      ..color = _blue.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * .72, height: 92),
      ring,
    );
    final cloud = Paint()..color = const Color(0xFFEAF4FF);
    final path = Path()
      ..moveTo(size.width * .15, size.height * .62)
      ..cubicTo(
        size.width * .14,
        size.height * .43,
        size.width * .3,
        size.height * .38,
        size.width * .4,
        size.height * .5,
      )
      ..cubicTo(
        size.width * .49,
        size.height * .26,
        size.width * .83,
        size.height * .34,
        size.width * .82,
        size.height * .59,
      )
      ..cubicTo(
        size.width * .95,
        size.height * .58,
        size.width * .95,
        size.height * .8,
        size.width * .76,
        size.height * .82,
      )
      ..lineTo(size.width * .24, size.height * .82)
      ..cubicTo(
        size.width * .08,
        size.height * .82,
        size.width * .05,
        size.height * .66,
        size.width * .15,
        size.height * .62,
      );
    canvas.drawShadow(path, Colors.black.withValues(alpha: .35), 16, false);
    canvas.drawPath(path, cloud);
    final rain = Paint()
      ..color = _blue.withValues(alpha: .7)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final x = size.width * (.22 + i * .08);
      canvas.drawLine(
        Offset(x, size.height * .87),
        Offset(x - 5, size.height * .97),
        rain,
      );
    }
    final sparkle = Paint()..color = _blue;
    final point = Offset(size.width * .86, size.height * .25);
    canvas.drawCircle(point, 3.5, sparkle);
    canvas.drawLine(
      point.translate(-13, 0),
      point.translate(13, 0),
      sparkle..strokeWidth = 1.2,
    );
    canvas.drawLine(point.translate(0, -13), point.translate(0, 13), sparkle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Quote extends StatelessWidget {
  const _Quote();

  @override
  Widget build(BuildContext context) => RichText(
    textAlign: TextAlign.center,
    text: const TextSpan(
      style: TextStyle(
        color: _white,
        fontSize: 16,
        height: 1.35,
        fontStyle: FontStyle.italic,
      ),
      children: [
        TextSpan(text: '“Look up. '),
        TextSpan(
          text: 'Every sky',
          style: TextStyle(color: _blue, fontWeight: FontWeight.w800),
        ),
        TextSpan(text: ' has a story to tell.”'),
      ],
    ),
  );
}
