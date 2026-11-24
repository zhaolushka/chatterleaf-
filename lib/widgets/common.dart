import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../theme/app_theme.dart';

/// Red "No connection" bar above any screen (M8).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) => AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: connectivity.online
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('No connection to the greenhouse. Showing the last saved data.',
                          style: nunito(14, FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: AppColors.black));
}

/// A friendly message instead of a crash.
class ErrorMessage extends StatelessWidget {
  const ErrorMessage(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center, style: nunito(15, FontWeight.w700, color: AppColors.muted)),
        ),
      );
}

/// White card with the soft shadow used everywhere.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 30, this.color = Colors.white});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: color == Colors.white ? AppColors.softShadow : null,
        ),
        child: child,
      );
}

/// Round white icon button (back, settings, bell).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.dot = false, this.size = 46});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool dot;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppColors.softShadow),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: AppColors.ink, size: 22),
                  if (dot)
                    Positioned(
                      top: 10,
                      right: 11,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Lime circle with an arrow — the brand detail of primary buttons.
class ArrowCircle extends StatelessWidget {
  const ArrowCircle({super.key, this.color = AppColors.lime, this.size = 38});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.ink),
      );
}

/// Primary black pill button: label left, lime arrow right.
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onTap, this.loading = false, this.height = 62, this.icon});
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(height / 2),
        elevation: 8,
        shadowColor: const Color(0x55211D26),
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: loading ? null : onTap,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 12),
              child: Row(
                children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                  Expanded(
                    child: Text(label, style: nunito(17, FontWeight.w900, color: Colors.white), overflow: TextOverflow.ellipsis),
                  ),
                  loading
                      ? const SizedBox(width: 38, height: 38, child: Padding(padding: EdgeInsets.all(9), child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.lime)))
                      : const ArrowCircle(),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Small status chip: "● Hot".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.dot, this.background = Colors.white, this.foreground = AppColors.ink, this.icon});
  final String label;
  final Color? dot;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 5)],
            Text(label, style: nunito(13, FontWeight.w900, color: foreground)),
          ],
        ),
      );
}

/// Big number with a small muted unit: 34.6 °C.
class BigNumber extends StatelessWidget {
  const BigNumber(this.value, this.unit, {super.key, this.size = 26, this.color = AppColors.ink});
  final String value;
  final String unit;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(text: value, style: nunito(size, FontWeight.w900, color: color, spacing: -0.6)),
        TextSpan(text: ' $unit', style: nunito(size * 0.5, FontWeight.w800, color: AppColors.muted)),
      ]));
}

/// Circular gauge used on the bed screen.
class RingGauge extends StatelessWidget {
  const RingGauge({super.key, required this.percent, required this.color, required this.value, required this.unit, required this.label, this.size = 74});
  final double percent; // 0..100
  final Color color;
  final String value;
  final String unit;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(percent.clamp(0, 100) / 100, color),
              child: Center(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: value, style: nunito(18, FontWeight.w900, spacing: -0.5)),
                    TextSpan(text: unit, style: nunito(10, FontWeight.w800, color: AppColors.muted)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: nunito(12, FontWeight.w800, color: AppColors.muted)),
        ],
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..color = AppColors.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * t, false, base..color = color..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.t != t || old.color != color;
}

/// Speech bubble with a small tail on top.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.center = true});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          SoftCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(text, textAlign: center ? TextAlign.center : TextAlign.start, style: nunito(16, FontWeight.w800, height: 1.35)),
          ),
          Positioned(
            top: -7,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
        ],
      );
}

/// Pill-shaped switch in brand colours.
class PillSwitch extends StatelessWidget {
  const PillSwitch({super.key, required this.value, required this.onChanged, required this.label});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        label: label,
        button: true,
        child: GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 58,
            height: 34,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: onChanged == null ? const Color(0xFFD9D3C7) : (value ? AppColors.limeDark : const Color(0xFFE3DDD1)),
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ),
      );
}

/// Segmented control: black selected pill on white.
class PillSegment<T> extends StatelessWidget {
  const PillSegment({super.key, required this.options, required this.selected, required this.onChanged});
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SoftCard(
        radius: 26,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final o in options)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(o.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: o.$1 == selected ? AppColors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(o.$2, style: nunito(15, FontWeight.w900, color: o.$1 == selected ? Colors.white : AppColors.muted)),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// Screen header: round back button, centred title + subtitle, optional right button.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.right});
  final String title;
  final String? subtitle;
  final Widget? right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          children: [
            RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onTap: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Column(
                children: [
                  Text(title, style: nunito(20, FontWeight.w900, spacing: -0.3), overflow: TextOverflow.ellipsis),
                  if (subtitle != null) Text(subtitle!, style: nunito(12, FontWeight.w700, color: AppColors.muted)),
                ],
              ),
            ),
            right ?? const SizedBox(width: 46),
          ],
        ),
      );
}
