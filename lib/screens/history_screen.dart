import 'dart:math' as math;

import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/mood.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';

enum _Period { day, week, month }

/// Screen 6. History & mood diary (M6): charts of temperature and soil moisture
/// built from stored history, with Day / Week / Month periods.
/// Scenario 4: find when the plant lacked water (the curve drops below the dashed target).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.greenhouseId});
  final String greenhouseId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Period _period = _Period.week;
  late final Stream<Greenhouse?> _bed = greenhouseRepository.watchGreenhouse(widget.greenhouseId);
  late Stream<List<HistoryPoint>> _points = _load();

  Stream<List<HistoryPoint>> _load() => greenhouseRepository.watchHistory(
      widget.greenhouseId, _period == _Period.day ? const Duration(days: 1) : const Duration(days: 31));

  void _setPeriod(_Period p) => setState(() {
        _period = p;
        _points = _load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Greenhouse?>(
          stream: _bed,
          builder: (context, bedSnap) {
            final g = bedSnap.data;
            return Column(children: [
              ScreenHeader(title: g == null ? 'Diary' : '${g.plantName}’s diary', subtitle: g?.name),
              Expanded(
                child: g == null
                    ? const Loading()
                    : StreamBuilder<List<HistoryPoint>>(
                        stream: _points,
                        builder: (context, snap) {
                          if (snap.hasError) return ErrorMessage('Could not load history.\n${snap.error}');
                          if (!snap.hasData) return const Loading();
                          return _content(g, snap.data!);
                        },
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _content(Greenhouse g, List<HistoryPoint> all) {
    final now = DateTime.now();
    final s = g.settings;
    final span = _period == _Period.day ? const Duration(days: 1) : const Duration(days: 7);
    final from = now.subtract(span);
    final pts = all.where((p) => p.ts.isAfter(from)).toList();
    final days = _dayMoods(all, s);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        PillSegment<_Period>(
          options: const [(_Period.day, 'Day'), (_Period.week, 'Week'), (_Period.month, 'Month')],
          selected: _period,
          onChanged: _setPeriod,
        ),
        const SizedBox(height: 12),
        if (_period == _Period.month)
          _MonthCalendar(cropKey: g.cropKey, moods: days, now: now)
        else if (_period == _Period.week)
          _WeekRow(cropKey: g.cropKey, moods: days, now: now),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Soil water',
          subtitle: 'Dashed line — target ${s.soilMin.round()} %',
          points: [for (final p in pts) (p.ts, p.soilMoisture)],
          from: from,
          to: now,
          minY: 0,
          maxY: 100,
          target: s.soilMin,
          color: const Color(0xFFEC5578),
          unit: '%',
          day: _period == _Period.day,
          warn: pts.any((p) => p.soilMoisture < s.soilMin),
        ),
        if (_period != _Period.month) ...[
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Temperature',
            subtitle: 'Comfort ${s.tempMin.round()}–${s.tempMax.round()} °C',
            points: [for (final p in pts) (p.ts, p.airTemp)],
            from: from,
            to: now,
            minY: math.min(s.tempMin - 10, 0.0),
            maxY: math.max(s.tempMax + 15, 40.0),
            target: s.tempMax,
            color: const Color(0xFFE0533F),
            unit: '°C',
            day: _period == _Period.day,
            warn: pts.any((p) => p.airTemp > s.tempMax || p.airTemp < s.tempMin),
          ),
        ],
      ],
    );
  }

  /// One mood per day: hot > cold > thirsty > happy.
  Map<DateTime, Mood> _dayMoods(List<HistoryPoint> pts, GreenhouseSettings s) {
    final byDay = <DateTime, List<HistoryPoint>>{};
    for (final p in pts) {
      byDay.putIfAbsent(DateTime(p.ts.year, p.ts.month, p.ts.day), () => []).add(p);
    }
    return byDay.map((day, list) {
      final hot = list.any((p) => p.airTemp > s.tempMax);
      final cold = list.any((p) => p.airTemp < s.tempMin);
      final dry = list.any((p) => p.soilMoisture < s.soilMin);
      return MapEntry(day, hot ? Mood.hot : cold ? Mood.cold : dry ? Mood.thirsty : Mood.happy);
    });
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.cropKey, required this.moods, required this.now});
  final String cropKey;
  final Map<DateTime, Mood> moods;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(color: AppColors.pastel(cropKey), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          for (var i = 6; i >= 0; i--)
            Expanded(
              child: Builder(builder: (context) {
                final d = today.subtract(Duration(days: i));
                final m = moods[d];
                return Column(children: [
                  Text(DateFormat.E().format(d).substring(0, 2), style: nunito(11, FontWeight.w800, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  m == null
                      ? const _Empty()
                      : PlantAvatar(cropKey: cropKey, mood: m, size: 38, shadow: false),
                  Text('${d.day}', style: nunito(11, FontWeight.w900)),
                ]);
              }),
            ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.cropKey, required this.moods, required this.now});
  final String cropKey;
  final Map<DateTime, Mood> moods;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final offset = first.weekday - 1; // Monday first
    final happyDays = moods.entries.where((e) => e.key.month == now.month && e.value == Mood.happy).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(color: AppColors.pastel(cropKey), borderRadius: BorderRadius.circular(30)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(children: [
            Text(DateFormat.yMMMM().format(now), style: nunito(17, FontWeight.w900)),
            const Spacer(),
            Text('Happy $happyDays days', style: nunito(12, FontWeight.w800, color: AppColors.muted)),
          ]),
        ),
        const SizedBox(height: 8),
        Row(children: [
          for (final w in const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
            Expanded(child: Center(child: Text(w, style: nunito(11, FontWeight.w800, color: AppColors.muted)))),
        ]),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          children: [
            for (var i = 0; i < offset; i++) const SizedBox(),
            for (var d = 1; d <= daysInMonth; d++)
              Builder(builder: (context) {
                final day = DateTime(now.year, now.month, d);
                final m = moods[day];
                final isToday = d == now.day;
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  m == null ? const _Empty() : PlantAvatar(cropKey: cropKey, mood: m, size: 34, shadow: false),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(color: isToday ? AppColors.black : null, borderRadius: BorderRadius.circular(8)),
                    child: Text('$d', style: nunito(11, FontWeight.w900, color: isToday ? Colors.white : (day.isAfter(now) ? AppColors.muted : AppColors.ink))),
                  ),
                ]);
              }),
          ],
        ),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle),
      );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.from,
    required this.to,
    required this.minY,
    required this.maxY,
    required this.target,
    required this.color,
    required this.unit,
    required this.day,
    required this.warn,
  });
  final String title, subtitle, unit;
  final List<(DateTime, double)> points;
  final DateTime from, to;
  final double minY, maxY, target;
  final Color color;
  final bool day, warn;

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: nunito(17, FontWeight.w900)),
            const Spacer(),
            if (warn) const StatusChip(label: 'Attention', dot: Color(0xFFEC5578), background: Color(0xFFFFE2EA)),
          ]),
          Text(subtitle, style: nunito(13, FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: points.length < 2
                ? Center(child: Text('Not enough data yet', style: nunito(13, FontWeight.w700, color: AppColors.muted)))
                : CustomPaint(
                    size: Size.infinite,
                    painter: _AreaChartPainter(points, from, to, minY, maxY, target, color, day),
                  ),
          ),
        ]),
      );
}

class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter(this.points, this.from, this.to, this.minY, this.maxY, this.target, this.color, this.day);
  final List<(DateTime, double)> points;
  final DateTime from, to;
  final double minY, maxY, target;
  final Color color;
  final bool day;

  @override
  void paint(Canvas canvas, Size size) {
    const bottom = 20.0, top = 8.0;
    final h = size.height - bottom - top;
    final span = to.difference(from).inMinutes.toDouble();
    double x(DateTime t) => size.width * (t.difference(from).inMinutes / span).clamp(0.0, 1.0);
    double y(double v) => top + h * (1 - ((v - minY) / (maxY - minY)).clamp(0.0, 1.0));

    // Labels on the time axis.
    final label = TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800);
    final ticks = day ? 4 : 7;
    for (var i = 0; i < ticks; i++) {
      final t = day ? from.add(Duration(hours: 6 * i + 3)) : from.add(Duration(days: i, hours: 12));
      final text = day ? DateFormat.Hm().format(DateTime(t.year, t.month, t.day, t.hour)) : DateFormat.E().format(t).substring(0, 2);
      final tp = TextPainter(text: TextSpan(text: text, style: label), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset((x(t) - tp.width / 2).clamp(0.0, size.width - tp.width), size.height - 14));
    }

    // Smooth line through the points (downsampled to ~60 for speed).
    final step = math.max(1, points.length ~/ 60);
    final sampled = [for (var i = 0; i < points.length; i += step) points[i], if ((points.length - 1) % step != 0) points.last];
    final path = Path()..moveTo(x(sampled.first.$1), y(sampled.first.$2));
    for (var i = 1; i < sampled.length; i++) {
      final x0 = x(sampled[i - 1].$1), y0 = y(sampled[i - 1].$2);
      final x1 = x(sampled[i].$1), y1 = y(sampled[i].$2);
      final mx = (x0 + x1) / 2;
      path.cubicTo(mx, y0, mx, y1, x1, y1);
    }
    final area = Path.from(path)
      ..lineTo(x(sampled.last.$1), top + h)
      ..lineTo(x(sampled.first.$1), top + h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.03)],
        ).createShader(Rect.fromLTWH(0, top, size.width, h)),
    );

    // Dashed target line.
    final ty = y(target);
    final dash = Paint()
      ..color = AppColors.green
      ..strokeWidth = 1.5;
    for (double dx = 0; dx < size.width; dx += 8) {
      canvas.drawLine(Offset(dx, ty), Offset(math.min(dx + 4, size.width), ty), dash);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final last = Offset(x(sampled.last.$1), y(sampled.last.$2));
    canvas.drawCircle(last, 7, Paint()..color = Colors.white);
    canvas.drawCircle(last, 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter old) => old.points != points || old.color != color;
}
