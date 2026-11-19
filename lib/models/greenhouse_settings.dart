class GreenhouseSettings {
  const GreenhouseSettings({
    required this.tempMin,
    required this.tempMax,
    required this.humMin,
    required this.humMax,
    required this.soilMin,
    required this.soilMax,
    required this.lightMin,
    required this.unit,
    required this.irrigationTime,
  });

  final double tempMin;
  final double tempMax;
  final double humMin;
  final double humMax;
  final double soilMin;
  final double soilMax;
  final double lightMin;
  final String unit; // "c" or "f"
  final String irrigationTime; // "HH:mm"

  bool get isCelsius => unit != 'f';

  GreenhouseSettings copyWith({
    double? tempMin,
    double? tempMax,
    double? humMin,
    double? humMax,
    double? soilMin,
    double? soilMax,
    double? lightMin,
    String? unit,
    String? irrigationTime,
  }) {
    return GreenhouseSettings(
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      humMin: humMin ?? this.humMin,
      humMax: humMax ?? this.humMax,
      soilMin: soilMin ?? this.soilMin,
      soilMax: soilMax ?? this.soilMax,
      lightMin: lightMin ?? this.lightMin,
      unit: unit ?? this.unit,
      irrigationTime: irrigationTime ?? this.irrigationTime,
    );
  }

  Map<String, dynamic> toMap() => {
        'tempMin': tempMin,
        'tempMax': tempMax,
        'humMin': humMin,
        'humMax': humMax,
        'soilMin': soilMin,
        'soilMax': soilMax,
        'lightMin': lightMin,
        'unit': unit,
        'irrigationTime': irrigationTime,
      };

  factory GreenhouseSettings.fromMap(Map<String, dynamic> data) {
    return GreenhouseSettings(
      tempMin: (data['tempMin'] as num?)?.toDouble() ?? 18,
      tempMax: (data['tempMax'] as num?)?.toDouble() ?? 30,
      humMin: (data['humMin'] as num?)?.toDouble() ?? 40,
      humMax: (data['humMax'] as num?)?.toDouble() ?? 80,
      soilMin: (data['soilMin'] as num?)?.toDouble() ?? 30,
      soilMax: (data['soilMax'] as num?)?.toDouble() ?? 70,
      lightMin: (data['lightMin'] as num?)?.toDouble() ?? 5000,
      unit: data['unit'] as String? ?? 'c',
      irrigationTime: data['irrigationTime'] as String? ?? '07:00',
    );
  }

  static GreenhouseSettings defaults() => const GreenhouseSettings(
        tempMin: 18,
        tempMax: 30,
        humMin: 40,
        humMax: 80,
        soilMin: 30,
        soilMax: 70,
        lightMin: 5000,
        unit: 'c',
        irrigationTime: '07:00',
      );

  /// Rejects min ≥ max and percentages outside 0–100.
  static String? validate(GreenhouseSettings s) {
    if (s.tempMin >= s.tempMax) {
      return 'Temperature min must be less than max.';
    }
    if (s.humMin >= s.humMax) {
      return 'Humidity min must be less than max.';
    }
    if (s.soilMin >= s.soilMax) {
      return 'Soil moisture min must be less than max.';
    }
    for (final value in [s.humMin, s.humMax, s.soilMin, s.soilMax]) {
      if (value < 0 || value > 100) {
        return 'Percentages must be between 0 and 100.';
      }
    }
    if (s.lightMin < 0) {
      return 'Light minimum cannot be negative.';
    }
    return null;
  }
}
