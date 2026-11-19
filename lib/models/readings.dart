class Readings {
  const Readings({
    required this.airTemp,
    required this.airHumidity,
    required this.soilMoisture,
    required this.light,
    required this.updatedAt,
  });

  final double airTemp; // °C
  final double airHumidity; // %
  final double soilMoisture; // %
  final double light; // lux
  final DateTime updatedAt;

  Readings copyWith({
    double? airTemp,
    double? airHumidity,
    double? soilMoisture,
    double? light,
    DateTime? updatedAt,
  }) {
    return Readings(
      airTemp: airTemp ?? this.airTemp,
      airHumidity: airHumidity ?? this.airHumidity,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      light: light ?? this.light,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'airTemp': airTemp,
        'airHumidity': airHumidity,
        'soilMoisture': soilMoisture,
        'light': light,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Readings.fromMap(Map<String, dynamic> data) {
    return Readings(
      airTemp: (data['airTemp'] as num?)?.toDouble() ?? 0,
      airHumidity: (data['airHumidity'] as num?)?.toDouble() ?? 0,
      soilMoisture: (data['soilMoisture'] as num?)?.toDouble() ?? 0,
      light: (data['light'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Readings demoHealthy() => Readings(
        airTemp: 24,
        airHumidity: 55,
        soilMoisture: 45,
        light: 12000,
        updatedAt: DateTime.now(),
      );
}
