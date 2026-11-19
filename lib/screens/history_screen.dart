import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/greenhouse_repository.dart';
import '../models/history_point.dart';
import '../theme/app_colors.dart';

enum _Param { temp, humidity, soil, light }
enum _Range { day, week }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Param _param = _Param.temp;
  _Range _range = _Range.day;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GreenhouseRepository>();
    final window =
        _range == _Range.day ? const Duration(hours: 24) : const Duration(days: 7);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Temp'),
                selected: _param == _Param.temp,
                onSelected: (_) => setState(() => _param = _Param.temp),
              ),
              ChoiceChip(
                label: const Text('Humidity'),
                selected: _param == _Param.humidity,
                onSelected: (_) => setState(() => _param = _Param.humidity),
              ),
              ChoiceChip(
                label: const Text('Soil'),
                selected: _param == _Param.soil,
                onSelected: (_) => setState(() => _param = _Param.soil),
              ),
              ChoiceChip(
                label: const Text('Light'),
                selected: _param == _Param.light,
                onSelected: (_) => setState(() => _param = _Param.light),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<_Range>(
            segments: const [
              ButtonSegment(value: _Range.day, label: Text('Day')),
              ButtonSegment(value: _Range.week, label: Text('Week')),
            ],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<HistoryPoint>>(
            stream: repo.watchHistory(window: window),
            builder: (context, snap) {
              final points = snap.data ?? const <HistoryPoint>[];
              if (points.isEmpty) {
                return const Center(
                  child: Text(
                    'No history yet.\nOpen Settings → Create demo data.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final spots = <FlSpot>[];
              for (var i = 0; i < points.length; i++) {
                spots.add(FlSpot(i.toDouble(), _value(points[i])));
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_label()} ($_unit())',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              minY: _minY(spots),
                              maxY: _maxY(spots),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (v) => FlLine(
                                  color: AppColors.muted.withValues(alpha: 0.2),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    interval: (points.length / 4)
                                        .clamp(1, 48)
                                        .toDouble(),
                                    getTitlesWidget: (v, meta) {
                                      final i = v.round();
                                      if (i < 0 || i >= points.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final t = points[i].ts;
                                      final label = _range == _Range.day
                                          ? '${t.hour.toString().padLeft(2, '0')}:00'
                                          : '${t.month}/${t.day}';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (v, meta) => Text(
                                      v.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: AppColors.primary,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                  ),
                                ),
                              ],
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
        ),
      ],
    );
  }

  double _value(HistoryPoint p) {
    switch (_param) {
      case _Param.temp:
        return p.airTemp;
      case _Param.humidity:
        return p.airHumidity;
      case _Param.soil:
        return p.soilMoisture;
      case _Param.light:
        return p.light;
    }
  }

  String _label() {
    switch (_param) {
      case _Param.temp:
        return 'Temperature';
      case _Param.humidity:
        return 'Humidity';
      case _Param.soil:
        return 'Soil moisture';
      case _Param.light:
        return 'Light';
    }
  }

  String _unit() {
    switch (_param) {
      case _Param.temp:
        return '°C';
      case _Param.humidity:
      case _Param.soil:
        return '%';
      case _Param.light:
        return 'lux';
    }
  }

  double _minY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    final m = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    return (m * 0.9).floorToDouble();
  }

  double _maxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;
    final m = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return (m * 1.1).ceilToDouble();
  }
}
