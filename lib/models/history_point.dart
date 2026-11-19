class HistoryPoint {
  const HistoryPoint({
    required this.id,
    required this.ts,
    required this.airTemp,
    required this.airHumidity,
    required this.soilMoisture,
    required this.light,
  });

  final String id;
  final DateTime ts;
  final double airTemp;
  final double airHumidity;
  final double soilMoisture;
  final double light;

  Map<String, dynamic> toMap() => {
        'ts': ts.toIso8601String(),
        'airTemp': airTemp,
        'airHumidity': airHumidity,
        'soilMoisture': soilMoisture,
        'light': light,
      };

  factory HistoryPoint.fromMap(String id, Map<String, dynamic> data) {
    return HistoryPoint(
      id: id,
      ts: DateTime.tryParse(data['ts'] as String? ?? '') ?? DateTime.now(),
      airTemp: (data['airTemp'] as num?)?.toDouble() ?? 0,
      airHumidity: (data['airHumidity'] as num?)?.toDouble() ?? 0,
      soilMoisture: (data['soilMoisture'] as num?)?.toDouble() ?? 0,
      light: (data['light'] as num?)?.toDouble() ?? 0,
    );
  }
}
