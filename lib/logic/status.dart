import '../data/models.dart';
import 'format.dart';

/// Overall status of a bed — scenario 1: understand everything in 5 seconds.
enum GhStatus { ok, warning, critical }

/// One problem: what is wrong and how serious it is.
class Problem {
  final String param; // airTemp, airHumidity, soilMoisture, light
  final String text; // "Too hot: 45 °C"
  final GhStatus level;
  const Problem(this.param, this.text, this.level);
}

/// The simulator writes data every 30 s (demo: 5 s). No new data for 2 minutes
/// means "no connection to the greenhouse" (M8: simulator stopped).
const kStaleAfter = Duration(minutes: 2);

bool isStale(Readings r, {DateTime? now}) {
  final t = r.updatedAt;
  if (t == null) return true;
  return (now ?? DateTime.now()).difference(t) > kStaleAfter;
}

/// Compares readings with the thresholds from settings.
/// Light is checked only in the daytime (9:00–17:00): darkness at night is normal.
List<Problem> findProblems(Readings r, GreenhouseSettings s, {DateTime? now}) {
  final problems = <Problem>[];
  final u = s.units;

  if (r.airTemp > s.tempMax) {
    final level = r.airTemp > s.tempMax + 5 ? GhStatus.critical : GhStatus.warning;
    problems.add(Problem('airTemp', 'Too hot: ${formatTemp(r.airTemp, u)}', level));
  } else if (r.airTemp < s.tempMin) {
    final level = r.airTemp < s.tempMin - 5 ? GhStatus.critical : GhStatus.warning;
    problems.add(Problem('airTemp', 'Too cold: ${formatTemp(r.airTemp, u)}', level));
  }

  if (r.airHumidity > s.humidityMax) {
    problems.add(Problem('airHumidity', 'Too humid: ${r.airHumidity.round()} %', GhStatus.warning));
  } else if (r.airHumidity < s.humidityMin) {
    problems.add(Problem('airHumidity', 'Dry air: ${r.airHumidity.round()} %', GhStatus.warning));
  }

  if (r.soilMoisture < s.soilMin) {
    final level = r.soilMoisture < s.soilMin - 10 ? GhStatus.critical : GhStatus.warning;
    problems.add(Problem('soilMoisture', 'Dry soil: ${r.soilMoisture.round()} %', level));
  }

  final hour = (now ?? DateTime.now()).hour;
  if (hour >= 9 && hour < 17 && r.light < s.lightMin) {
    problems.add(Problem('light', 'Not enough light: ${formatLux(r.light)}', GhStatus.warning));
  }

  return problems;
}

GhStatus statusOf(Greenhouse g, {DateTime? now}) {
  final problems = findProblems(g.current, g.settings, now: now);
  if (problems.any((p) => p.level == GhStatus.critical)) return GhStatus.critical;
  if (problems.isNotEmpty) return GhStatus.warning;
  return GhStatus.ok;
}

String statusLabel(GhStatus s) {
  switch (s) {
    case GhStatus.ok:
      return 'All good';
    case GhStatus.warning:
      return 'Needs attention';
    case GhStatus.critical:
      return 'Urgent!';
  }
}
