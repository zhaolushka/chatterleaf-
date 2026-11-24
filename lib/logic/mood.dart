import '../data/models.dart';
import 'status.dart';

/// Mood of the plant character. Computed from data only (no Flutter),
/// so it is easy to test.
enum Mood { happy, hot, cold, thirsty, sleepy }

/// Priority: asleep (no data) first, then temperature, then water.
Mood moodOf(Greenhouse g, {bool online = true, DateTime? now}) {
  if (!online || isStale(g.current, now: now)) return Mood.sleepy;
  final r = g.current;
  final s = g.settings;
  if (r.airTemp > s.tempMax) return Mood.hot;
  if (r.airTemp < s.tempMin) return Mood.cold;
  if (r.soilMoisture < s.soilMin) return Mood.thirsty;
  return Mood.happy;
}

String moodLabel(Mood m) {
  switch (m) {
    case Mood.happy:
      return 'Happy';
    case Mood.hot:
      return 'Too hot';
    case Mood.cold:
      return 'Cold';
    case Mood.thirsty:
      return 'Thirsty';
    case Mood.sleepy:
      return 'Asleep — no data';
  }
}

/// Does the plant need help? (for the summary card on the home screen)
bool needsHelp(Mood m) => m == Mood.hot || m == Mood.cold || m == Mood.thirsty;
