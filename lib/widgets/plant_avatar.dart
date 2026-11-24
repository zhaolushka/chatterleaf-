import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../logic/mood.dart';
import '../theme/app_theme.dart';

/// Kawaii sticker character: tomato (Tomi), cucumber (Cuke), strawberry (Berry), dill (Dilly).
/// White sticker outline + soft shadow. The face changes with the mood:
/// happy, hot (sweat drop), thirsty (sad brows), cold (blue, chattering), sleepy (no data).
class PlantAvatar extends StatefulWidget {
  const PlantAvatar({
    super.key,
    required this.cropKey,
    required this.mood,
    this.size = 96,
    this.animate = false,
    this.shadow = true,
  });

  final String cropKey;
  final Mood mood;
  final double size;
  final bool animate;
  final bool shadow;

  @override
  State<PlantAvatar> createState() => _PlantAvatarState();
}

class _PlantAvatarState extends State<PlantAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PlantAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood || old.animate != widget.animate) _sync();
  }

  void _sync() {
    final moving = widget.animate && widget.mood != Mood.sleepy;
    if (moving && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!moving) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(widget.size),
      painter: _StickerPainter(widget.cropKey, widget.mood, widget.shadow),
    );
    return Semantics(
      label: 'Plant, ${moodLabel(widget.mood)}',
      child: widget.animate
          ? AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_c.value);
                final u = widget.size / 120;
                final dy = widget.mood == Mood.happy ? -4 * t * u : 0.0;
                final dx = widget.mood == Mood.cold ? math.sin(_c.value * math.pi * 12) * 1.2 * u : 0.0;
                return Transform.translate(offset: Offset(dx, dy), child: child);
              },
              child: paint,
            )
          : paint,
    );
  }
}

/// Character on a soft glowing disc with a ground shadow (as in the mockups).
class GlowAvatar extends StatelessWidget {
  const GlowAvatar({super.key, required this.cropKey, required this.mood, required this.size, this.animate = false});
  final String cropKey;
  final Mood mood;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final disc = size * 1.18;
    return SizedBox(
      width: disc,
      height: disc,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                colors: [Colors.white, AppColors.glow(cropKey), AppColors.glow(cropKey).withValues(alpha: 0)],
                stops: const [0, 0.62, 0.72],
              ),
            ),
          ),
          Positioned(
            bottom: disc * 0.05,
            child: Container(
              width: disc * 0.56,
              height: disc * 0.07,
              decoration: BoxDecoration(color: const Color(0x1A211D26), borderRadius: BorderRadius.circular(disc)),
            ),
          ),
          PlantAvatar(cropKey: cropKey, mood: mood, size: size, animate: animate, shadow: false),
        ],
      ),
    );
  }
}

class _StickerPainter extends CustomPainter {
  _StickerPainter(this.crop, this.mood, this.shadow);
  final String crop;
  final Mood mood;
  final bool shadow;

  static const _ink = Color(0xFF3A2E39);

  Color _t(Color c) {
    if (mood == Mood.sleepy) return Color.lerp(c, const Color(0xFFC9C4D3), 0.65)!;
    if (mood == Mood.cold) return Color.lerp(c, const Color(0xFF9ED0FF), 0.4)!;
    return c;
  }

  Paint _fill(Color c) => Paint()..color = c;
  Paint _line(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Path _star(double cx, double cy, double r, int n) {
    final p = Path();
    for (var i = 0; i < n * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / n;
      final rr = i.isEven ? r : r * 0.42;
      final x = cx + math.cos(a) * rr, y = cy + math.sin(a) * rr * 0.7;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    return p..close();
  }

  static final _berry = Path()
    ..moveTo(60, 112)
    ..cubicTo(30, 100, 20, 70, 26, 50)
    ..cubicTo(30, 38, 44, 36, 60, 38)
    ..cubicTo(76, 36, 90, 38, 94, 50)
    ..cubicTo(100, 70, 90, 100, 60, 112)
    ..close();

  static const _blobs = [(60.0, 62.0, 26.0), (40.0, 72.0, 20.0), (80.0, 72.0, 20.0), (50.0, 50.0, 18.0), (72.0, 50.0, 18.0), (60.0, 84.0, 22.0)];

  /// Silhouette used for the white sticker border and the shadow.
  void _outline(Canvas c, Paint p) {
    switch (crop) {
      case 'tomato':
        c.drawCircle(const Offset(60, 68), 38, p);
        c.drawPath(_star(60, 34, 20, 5), p);
      case 'cucumber':
        c.save();
        _rotateAround(c, 60, 66, 18);
        c.drawRRect(RRect.fromLTRBR(38, 20, 82, 112, const Radius.circular(22)), p);
        c.drawRRect(RRect.fromLTRBR(54, 12, 66, 22, const Radius.circular(4)), p);
        c.restore();
      case 'strawberry':
        c.drawPath(_berry, p);
        c.drawPath(_star(60, 38, 22, 6), p);
      default:
        for (final b in _blobs) {
          c.drawCircle(Offset(b.$1, b.$2), b.$3, p);
        }
        c.drawRRect(RRect.fromLTRBR(47, 100, 73, 114, const Radius.circular(4)), p);
    }
  }

  void _rotateAround(Canvas c, double x, double y, double degrees) {
    c.translate(x, y);
    c.rotate(degrees * math.pi / 180);
    c.translate(-x, -y);
  }

  void _ellipse(Canvas c, double cx, double cy, double rx, double ry, Paint p, [double rotDeg = 0]) {
    c.save();
    c.translate(cx, cy);
    if (rotDeg != 0) c.rotate(rotDeg * math.pi / 180);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), p);
    c.restore();
  }

  /// Returns the face centre for this crop.
  Offset _body(Canvas c) {
    const leaf = Color(0xFF43A35A);
    switch (crop) {
      case 'tomato':
        c.drawCircle(const Offset(60, 68), 38, _fill(_t(const Color(0xFFFF6F61))));
        _ellipse(c, 44, 52, 10, 6, _fill(Colors.white.withValues(alpha: 0.45)), -30);
        final star = _star(60, 34, 20, 5);
        c.drawPath(star, _fill(_t(leaf)));
        c.drawPath(star, _line(_t(leaf), 3));
        c.drawPath(Path()..moveTo(60, 32)..quadraticBezierTo(62, 22, 68, 19), _line(_t(leaf), 4));
        return const Offset(60, 72);
      case 'cucumber':
        c.save();
        _rotateAround(c, 60, 66, 18);
        c.drawRRect(RRect.fromLTRBR(38, 20, 82, 112, const Radius.circular(22)), _fill(_t(const Color(0xFF58B26C))));
        c.drawRRect(RRect.fromLTRBR(46, 28, 54, 88, const Radius.circular(4)), _fill(Colors.white.withValues(alpha: 0.3)));
        for (final d in const [Offset(72, 34), Offset(76, 56), Offset(70, 80), Offset(46, 98), Offset(74, 100)]) {
          c.drawCircle(d, 2.2, _fill(_t(const Color(0xFF3F9455))));
        }
        c.drawRRect(RRect.fromLTRBR(54, 12, 66, 22, const Radius.circular(4)), _fill(_t(const Color(0xFF3F9455))));
        c.restore();
        return const Offset(58, 64);
      case 'strawberry':
        c.drawPath(_berry, _fill(_t(const Color(0xFFFF6B8A))));
        _ellipse(c, 40, 58, 7, 5, _fill(Colors.white.withValues(alpha: 0.4)), -30);
        for (final s in const [Offset(36, 74), Offset(84, 74), Offset(44, 94), Offset(76, 94), Offset(60, 102), Offset(84, 56), Offset(70, 52)]) {
          _ellipse(c, s.dx, s.dy, 1.8, 2.8, _fill(const Color(0xFFFFF3B0)));
        }
        final star = _star(60, 38, 22, 6);
        c.drawPath(star, _fill(_t(leaf)));
        c.drawPath(star, _line(_t(leaf), 3));
        return const Offset(60, 72);
      default:
        for (final b in _blobs) {
          c.drawCircle(Offset(b.$1, b.$2), b.$3, _fill(_t(const Color(0xFF7CC66A))));
        }
        final frond = _line(_t(const Color(0xFF3E9B4F)), 2.5);
        for (final f in const [Offset(42, 40), Offset(60, 34), Offset(78, 40), Offset(30, 60), Offset(90, 60)]) {
          c.drawLine(f, f + const Offset(-5, -6), frond);
          c.drawLine(f, f + const Offset(5, -6), frond);
          c.drawLine(f + const Offset(0, -6), f + const Offset(-4, -11), frond);
          c.drawLine(f + const Offset(0, -6), f + const Offset(4, -11), frond);
        }
        c.drawRRect(RRect.fromLTRBR(50, 100, 70, 114, const Radius.circular(4)), _fill(_t(const Color(0xFF4E9A45))));
        c.drawRRect(RRect.fromLTRBR(47, 102, 73, 108, const Radius.circular(3)), _fill(_t(const Color(0xFFE9B872))));
        return const Offset(60, 68);
    }
  }

  void _face(Canvas c, Offset f) {
    final ink = mood == Mood.sleepy ? const Color(0xFF6B6475) : _ink;
    final cx = f.dx, cy = f.dy;
    final eyes = [Offset(cx - 13, cy - 2), Offset(cx + 13, cy - 2)];

    for (var i = 0; i < 2; i++) {
      final e = eyes[i];
      final s = i == 0 ? 1.0 : -1.0;
      switch (mood) {
        case Mood.sleepy:
          c.drawPath(Path()..moveTo(e.dx - 4, e.dy)..quadraticBezierTo(e.dx, e.dy + 4, e.dx + 4, e.dy), _line(ink, 2.6));
        case Mood.thirsty:
          _ellipse(c, e.dx, e.dy + 1, 4.2, 5, _fill(ink));
          c.drawCircle(Offset(e.dx + 1.4, e.dy - 1), 1.5, _fill(Colors.white));
          c.drawLine(Offset(e.dx - 5 * s, e.dy - 6), Offset(e.dx + 3 * s, e.dy - 10), _line(ink, 2.4));
        case Mood.hot:
          c.drawPath(
              Path()
                ..moveTo(e.dx - 4 * s, e.dy - 3)
                ..relativeLineTo(6 * s, 3)
                ..relativeLineTo(-6 * s, 3),
              _line(ink, 2.6));
        case Mood.happy:
        case Mood.cold:
          _ellipse(c, e.dx, e.dy, 4.4, 5.6, _fill(ink));
          c.drawCircle(Offset(e.dx + 1.5, e.dy - 2.2), 1.8, _fill(Colors.white));
      }
    }

    if (mood != Mood.sleepy) {
      final blush = mood == Mood.hot ? const Color(0xF2FF7F8E) : const Color(0xB3FFA3B1);
      _ellipse(c, cx - 21, cy + 5, 5.5, 3.4, _fill(blush));
      _ellipse(c, cx + 21, cy + 5, 5.5, 3.4, _fill(blush));
    }

    final my = cy + 7;
    switch (mood) {
      case Mood.happy:
        c.drawPath(
            Path()
              ..moveTo(cx - 5, my)
              ..quadraticBezierTo(cx - 2.5, my + 3.5, cx, my)
              ..quadraticBezierTo(cx + 2.5, my + 3.5, cx + 5, my),
            _line(ink, 2.4));
      case Mood.hot:
        c.drawPath(
            Path()
              ..moveTo(cx - 5, my + 1)
              ..quadraticBezierTo(cx - 2.5, my - 2, cx, my + 1)
              ..quadraticBezierTo(cx + 2.5, my + 4, cx + 5, my + 1),
            _line(ink, 2.4));
      case Mood.thirsty:
        c.drawPath(Path()..moveTo(cx - 5, my + 4)..quadraticBezierTo(cx, my - 1, cx + 5, my + 4), _line(ink, 2.6));
      case Mood.cold:
        final r = RRect.fromLTRBR(cx - 6, my - 1, cx + 6, my + 5, const Radius.circular(2));
        c.drawRRect(r, _fill(Colors.white));
        c.drawRRect(r, _line(ink, 2));
        c.drawLine(Offset(cx - 2, my - 1), Offset(cx - 2, my + 5), _line(ink, 1.4));
        c.drawLine(Offset(cx + 2, my - 1), Offset(cx + 2, my + 5), _line(ink, 1.4));
      case Mood.sleepy:
        c.drawLine(Offset(cx - 3, my + 1), Offset(cx + 3, my + 1), _line(ink, 2.4));
    }
  }

  void _extras(Canvas c) {
    switch (mood) {
      case Mood.hot:
        final drop = Path()
          ..moveTo(98, 34)
          ..quadraticBezierTo(91, 44, 98, 47)
          ..quadraticBezierTo(105, 44, 98, 34)
          ..close();
        c.drawPath(drop, _fill(const Color(0xFF6BB8FF)));
        c.drawPath(drop, _line(Colors.white, 2.5));
      case Mood.thirsty:
        final tear = Path()
          ..moveTo(30, 40)
          ..quadraticBezierTo(25, 47, 30, 50)
          ..quadraticBezierTo(35, 47, 30, 40)
          ..close();
        c.drawPath(tear, _fill(const Color(0xFF6BB8FF)));
        c.drawPath(tear, _line(Colors.white, 2));
      case Mood.cold:
        final p = _line(const Color(0xFF7FB8F0), 3);
        c.drawLine(const Offset(14, 54), const Offset(22, 54), p);
        c.drawLine(const Offset(12, 64), const Offset(20, 64), p);
        c.drawLine(const Offset(98, 54), const Offset(106, 54), p);
        c.drawLine(const Offset(100, 64), const Offset(108, 64), p);
      case Mood.sleepy:
        _z(c, 88, 34, 18);
        _z(c, 100, 22, 12);
      case Mood.happy:
        break;
    }
  }

  void _z(Canvas c, double x, double baseline, double size) {
    final tp = TextPainter(
      text: TextSpan(text: 'z', style: TextStyle(color: const Color(0xFF8D86A0), fontSize: size, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x, baseline - size * 0.85));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 132, size.height / 132);
    canvas.translate(6, 6);

    canvas.save();
    if (mood == Mood.thirsty) _rotateAround(canvas, 60, 110, -6);

    if (shadow) {
      canvas.saveLayer(const Rect.fromLTWH(-20, -20, 170, 170), Paint()..color = const Color(0x1A000000));
      canvas.translate(0, 4);
      final sh = Paint()..color = const Color(0xFF3A2E39);
      final shStroke = _line(const Color(0xFF3A2E39), 12);
      _outline(canvas, sh);
      _outline(canvas, shStroke);
      canvas.restore();
    }
    _outline(canvas, _fill(Colors.white));
    _outline(canvas, _line(Colors.white, 12));
    final face = _body(canvas);
    _face(canvas, face);
    canvas.restore();

    _extras(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StickerPainter old) => old.crop != crop || old.mood != mood || old.shadow != shadow;
}
