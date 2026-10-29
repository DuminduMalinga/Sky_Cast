// Renders the SkyCast app icon layers into assets/icon/.
//
//   flutter test tool/generate_icon_test.dart
//
// Produces a 1024x1024 full icon (iOS / store), and the transparent
// foreground + background layers used by Android adaptive icons. The platform
// icon sizes are then cut from these by tool/build_icons.py.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;
const _midnight = Color(0xFF101B36);
const _deep = Color(0xFF0B1220);
const _blue = Color(0xFF63B8FF);
const _cyan = Color(0xFF9EE6FF);
const _cloudWhite = Color(0xFFF4F8FF);

void _background(Canvas canvas) {
  const rect = Rect.fromLTWH(0, 0, _size, _size);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(_size * .5, _size * .42),
        _size * .78,
        const [Color(0xFF1F3568), _midnight, _deep],
        const [0, .52, 1],
      ),
  );
}

/// Half of the atmospheric orbit: [back] is the far side (behind the sun and
/// cloud), otherwise the near side that wraps in front of the cloud.
void _orbit(Canvas canvas, {required bool back}) {
  const rx = 288.0, ry = 118.0;
  canvas.save();
  canvas.translate(_size * .5, _size * .5);
  canvas.rotate(-18 * math.pi / 180);
  final rect = Rect.fromCenter(
    center: Offset.zero,
    width: rx * 2,
    height: ry * 2,
  );
  final alpha = back ? .55 : 1.0;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = back ? 14 : 18
    ..shader = ui.Gradient.linear(
      const Offset(-rx, 0),
      const Offset(rx, 0),
      [
        _blue.withValues(alpha: 0),
        _blue.withValues(alpha: alpha),
        _cyan.withValues(alpha: alpha),
        _cyan.withValues(alpha: 0),
      ],
      const [0, .24, .6, .9],
    );
  canvas.drawArc(rect, back ? math.pi : 0, math.pi, false, paint);
  canvas.restore();
}

void _sun(Canvas canvas, Offset center) {
  // Restrained blue atmosphere, then a warm bloom, then the disc.
  canvas.drawCircle(
    center,
    225,
    Paint()
      ..color = _blue.withValues(alpha: .36)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
  );
  canvas.drawCircle(
    center,
    165,
    Paint()
      ..color = const Color(0xFFFFC15E).withValues(alpha: .5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 46),
  );
  canvas.drawCircle(
    center,
    140,
    Paint()
      ..shader = ui.Gradient.radial(
        center.translate(-38, -44),
        170,
        const [Color(0xFFFFF6D0), Color(0xFFFFD98A), Color(0xFFFFAE4D)],
        const [0, .5, 1],
      ),
  );
}

Path _cloudPath() {
  final base = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(246, 548, 532, 142),
        const Radius.circular(71),
      ),
    );
  Path circle(double x, double y, double r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
  var cloud = base;
  for (final part in [
    circle(372, 566, 100),
    circle(538, 500, 146),
    circle(682, 574, 84),
  ]) {
    cloud = Path.combine(PathOperation.union, cloud, part);
  }
  return cloud;
}

void _cloud(Canvas canvas) {
  final cloud = _cloudPath();
  final bounds = cloud.getBounds();

  canvas.drawPath(
    cloud.shift(const Offset(0, 26)),
    Paint()
      ..color = _deep.withValues(alpha: .6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
  );
  canvas.drawPath(
    cloud,
    Paint()
      ..shader = ui.Gradient.linear(
        bounds.topCenter,
        bounds.bottomCenter,
        const [Color(0xFFFFFFFF), _cloudWhite, Color(0xFFC4DDF6)],
        const [0, .5, 1],
      ),
  );

  // Soft volume: cool cyan light pooling along the underside, and a bright
  // top-left sheen. Both are clipped to the cloud silhouette.
  canvas.save();
  canvas.clipPath(cloud);
  canvas.drawRect(
    bounds,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, bounds.bottom - 90),
        Offset(0, bounds.bottom),
        [_cyan.withValues(alpha: 0), _cyan.withValues(alpha: .55)],
      ),
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(470, 400), width: 280, height: 130),
    Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: .75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
  );
  canvas.restore();
}

void _sparkle(Canvas canvas, Offset c, double r) {
  canvas.drawCircle(
    c,
    r * 1.5,
    Paint()
      ..color = _blue.withValues(alpha: .6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .8),
  );
  final k = r * .16;
  final star = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
    ..close();
  canvas.drawPath(
    star,
    Paint()
      ..shader = ui.Gradient.radial(c, r, const [
        Color(0xFFFFFFFF),
        _cyan,
        _blue,
      ], const [0, .35, 1]),
  );
}

void _symbol(Canvas canvas, {double scale = 1}) {
  canvas.save();
  canvas.translate(_size * .5, _size * .5);
  canvas.scale(scale);
  canvas.translate(-_size * .5, -_size * .5 + 18);
  _orbit(canvas, back: true);
  _sun(canvas, const Offset(610, 384));
  _cloud(canvas);
  _orbit(canvas, back: false);
  _sparkle(canvas, const Offset(766, 292), 48);
  canvas.restore();
}

Future<void> _write(String path, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder, const Rect.fromLTWH(0, 0, _size, _size)));
  final image = await recorder.endRecording().toImage(1024, 1024);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate SkyCast icon layers', (tester) async {
    await tester.runAsync(() async {
      await _write('assets/icon/skycast_icon.png', (canvas) {
        _background(canvas);
        _symbol(canvas);
      });
      // Scaled in so the artwork stays inside Android's circular safe zone.
      await _write(
        'assets/icon/skycast_icon_foreground.png',
        (canvas) => _symbol(canvas, scale: .9),
      );
      await _write('assets/icon/skycast_icon_background.png', _background);
    });
  });
}
