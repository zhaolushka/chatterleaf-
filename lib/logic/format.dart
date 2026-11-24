import 'package:intl/intl.dart' show DateFormat;

/// Temperature in the chosen units. The database always stores °C.
String formatTemp(double celsius, String units) {
  if (units == 'F') return '${(celsius * 9 / 5 + 32).toStringAsFixed(0)} °F';
  return '${celsius.toStringAsFixed(1)} °C';
}

/// Number and unit separately, for big numbers with a small unit in the UI.
(String, String) tempParts(double celsius, String units) {
  if (units == 'F') return ((celsius * 9 / 5 + 32).toStringAsFixed(0), '°F');
  return (celsius.toStringAsFixed(1), '°C');
}

String formatLux(double lux) => lux >= 1000 ? '${(lux / 1000).toStringAsFixed(1)}k lux' : '${lux.round()} lux';

String formatPercent(double v) => '${v.round()} %';

/// "just now", "5 min ago", "today 14:30", "24.11 14:30".
String timeAgo(DateTime? t, {DateTime? now}) {
  if (t == null) return 'no data';
  final n = now ?? DateTime.now();
  final diff = n.difference(t);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 && n.day == t.day) return 'today ${DateFormat.Hm().format(t)}';
  return DateFormat('d MMM, HH:mm').format(t);
}

String formatTime(DateTime? t) => t == null ? '' : DateFormat.Hm().format(t);
String formatDateTime(DateTime? t) => t == null ? '—' : DateFormat('d MMM, HH:mm').format(t);

/// Who switched a device.
String byLabel(String by) {
  switch (by) {
    case 'auto':
      return 'Auto';
    case 'schedule':
      return 'Schedule';
    default:
      return 'On duty';
  }
}
