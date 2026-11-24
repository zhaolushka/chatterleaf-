// Data models used by every screen.
// They know nothing about Firebase: repositories convert database rows into
// these classes, so the same screens work with the demo database and Firebase.

double _num(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;
String _str(dynamic v, [String fallback = '']) => v is String ? v : fallback;
DateTime? _time(dynamic v) => v is DateTime ? v : null;
Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// The signed-in user.
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  const AppUser({required this.uid, required this.email, required this.displayName});
}

/// Current sensor readings of one bed.
class Readings {
  final double airTemp; // °C
  final double airHumidity; // %
  final double soilMoisture; // %
  final double light; // lux
  final DateTime? updatedAt;

  const Readings({
    required this.airTemp,
    required this.airHumidity,
    required this.soilMoisture,
    required this.light,
    this.updatedAt,
  });

  factory Readings.fromMap(Map<String, dynamic>? m) {
    final map = m ?? const {};
    return Readings(
      airTemp: _num(map['airTemp']),
      airHumidity: _num(map['airHumidity']),
      soilMoisture: _num(map['soilMoisture']),
      light: _num(map['light']),
      updatedAt: _time(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'airTemp': airTemp,
        'airHumidity': airHumidity,
        'soilMoisture': soilMoisture,
        'light': light,
        'updatedAt': updatedAt,
      };

  Readings copyWith({double? airTemp, double? airHumidity, double? soilMoisture, double? light, DateTime? updatedAt}) =>
      Readings(
        airTemp: airTemp ?? this.airTemp,
        airHumidity: airHumidity ?? this.airHumidity,
        soilMoisture: soilMoisture ?? this.soilMoisture,
        light: light ?? this.light,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Bed settings: thresholds, schedule, units (M7).
class GreenhouseSettings {
  final double tempMin;
  final double tempMax;
  final double humidityMin;
  final double humidityMax;
  final double soilMin;
  final double lightMin;
  final int irrigationMinutes;
  final String lightOnAt; // "06:00"
  final String lightOffAt; // "20:00"
  final String units; // "C" or "F"

  const GreenhouseSettings({
    this.tempMin = 15,
    this.tempMax = 32,
    this.humidityMin = 50,
    this.humidityMax = 85,
    this.soilMin = 30,
    this.lightMin = 2000,
    this.irrigationMinutes = 2,
    this.lightOnAt = '06:00',
    this.lightOffAt = '20:00',
    this.units = 'C',
  });

  factory GreenhouseSettings.fromMap(Map<String, dynamic>? m) {
    const d = GreenhouseSettings();
    final map = m ?? const {};
    return GreenhouseSettings(
      tempMin: _num(map['tempMin'], d.tempMin),
      tempMax: _num(map['tempMax'], d.tempMax),
      humidityMin: _num(map['humidityMin'], d.humidityMin),
      humidityMax: _num(map['humidityMax'], d.humidityMax),
      soilMin: _num(map['soilMin'], d.soilMin),
      lightMin: _num(map['lightMin'], d.lightMin),
      irrigationMinutes: _num(map['irrigationMinutes'], d.irrigationMinutes.toDouble()).round(),
      lightOnAt: _str(map['lightOnAt'], d.lightOnAt),
      lightOffAt: _str(map['lightOffAt'], d.lightOffAt),
      units: _str(map['units'], d.units),
    );
  }

  Map<String, dynamic> toMap() => {
        'tempMin': tempMin,
        'tempMax': tempMax,
        'humidityMin': humidityMin,
        'humidityMax': humidityMax,
        'soilMin': soilMin,
        'lightMin': lightMin,
        'irrigationMinutes': irrigationMinutes,
        'lightOnAt': lightOnAt,
        'lightOffAt': lightOffAt,
        'units': units,
      };

  GreenhouseSettings copyWith({
    double? tempMin,
    double? tempMax,
    double? humidityMin,
    double? humidityMax,
    double? soilMin,
    String? units,
  }) =>
      GreenhouseSettings(
        tempMin: tempMin ?? this.tempMin,
        tempMax: tempMax ?? this.tempMax,
        humidityMin: humidityMin ?? this.humidityMin,
        humidityMax: humidityMax ?? this.humidityMax,
        soilMin: soilMin ?? this.soilMin,
        lightMin: lightMin,
        irrigationMinutes: irrigationMinutes,
        lightOnAt: lightOnAt,
        lightOffAt: lightOffAt,
        units: units ?? this.units,
      );

  /// Checks values before saving. Returns an error message, or null if all is fine.
  /// Protects against values like −50 % in the stress test.
  String? validate() {
    if (tempMin < -10 || tempMax > 50) return 'Temperature must be between −10 and 50 °C';
    if (tempMin >= tempMax) return 'Min temperature must be lower than max temperature';
    if (humidityMin < 0 || humidityMax > 100) return 'Air humidity must be between 0 and 100 %';
    if (humidityMin >= humidityMax) return 'Min humidity must be lower than max humidity';
    if (soilMin < 0 || soilMin > 100) return 'Soil moisture must be between 0 and 100 %';
    if (lightMin < 0 || lightMin > 100000) return 'Light must be between 0 and 100,000 lux';
    if (irrigationMinutes < 1 || irrigationMinutes > 60) return 'Watering time must be 1–60 minutes';
    final time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    if (!time.hasMatch(lightOnAt) || !time.hasMatch(lightOffAt)) return 'Use HH:MM time, for example 06:00';
    return null;
  }
}

/// One bed of the school greenhouse with its plant character.
/// In the database it is a document of the `greenhouses` collection.
class Greenhouse {
  final String id;
  final String ownerId;
  final String name; // "Bed 1"
  final String plantName; // "Tomi"
  final String cropKey; // tomato, cucumber, strawberry, greens
  final String personality; // cheerful, grumpy, gentle, joker
  final String place;
  final String mode; // "manual" or "auto"
  final Readings current;
  final GreenhouseSettings settings;

  const Greenhouse({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.plantName,
    required this.cropKey,
    required this.personality,
    required this.place,
    required this.mode,
    required this.current,
    required this.settings,
  });

  bool get isAuto => mode == 'auto';

  factory Greenhouse.fromMap(String id, Map<String, dynamic> m) => Greenhouse(
        id: id,
        ownerId: _str(m['ownerId']),
        name: _str(m['name'], 'Bed'),
        plantName: _str(m['plantName'], 'Sprout'),
        cropKey: _str(m['cropKey'], 'greens'),
        personality: _str(m['personality'], 'cheerful'),
        place: _str(m['place']),
        mode: _str(m['mode'], 'manual'),
        current: Readings.fromMap(_map(m['current'])),
        settings: GreenhouseSettings.fromMap(_map(m['settings'])),
      );

  Greenhouse copyWith({String? mode, Readings? current, GreenhouseSettings? settings}) => Greenhouse(
        id: id,
        ownerId: ownerId,
        name: name,
        plantName: plantName,
        cropKey: cropKey,
        personality: personality,
        place: place,
        mode: mode ?? this.mode,
        current: current ?? this.current,
        settings: settings ?? this.settings,
      );
}

/// Virtual device: irrigation, window, light, heater (M3).
class Device {
  final String id;
  final String name;
  final bool isOn;
  final String changedBy; // user, auto, schedule
  final DateTime? changedAt;
  final int order;

  const Device({
    required this.id,
    required this.name,
    required this.isOn,
    required this.changedBy,
    required this.changedAt,
    required this.order,
  });

  factory Device.fromMap(String id, Map<String, dynamic> m) => Device(
        id: id,
        name: _str(m['name'], id),
        isOn: m['isOn'] == true,
        changedBy: _str(m['changedBy'], 'user'),
        changedAt: _time(m['changedAt']),
        order: _num(m['order']).round(),
      );

  Device copyWith({bool? isOn, String? changedBy, DateTime? changedAt}) => Device(
        id: id,
        name: name,
        isOn: isOn ?? this.isOn,
        changedBy: changedBy ?? this.changedBy,
        changedAt: changedAt ?? this.changedAt,
        order: order,
      );
}

/// One history point for charts (M6).
class HistoryPoint {
  final DateTime ts;
  final double airTemp;
  final double airHumidity;
  final double soilMoisture;
  final double light;

  const HistoryPoint({
    required this.ts,
    required this.airTemp,
    required this.airHumidity,
    required this.soilMoisture,
    required this.light,
  });

  factory HistoryPoint.fromMap(Map<String, dynamic> m) => HistoryPoint(
        ts: _time(m['ts']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        airTemp: _num(m['airTemp']),
        airHumidity: _num(m['airHumidity']),
        soilMoisture: _num(m['soilMoisture']),
        light: _num(m['light']),
      );
}

/// Activity log entry: who switched what and when.
class DeviceEvent {
  final DateTime? ts;
  final String deviceId;
  final bool isOn;
  final String by; // user, auto, schedule
  final String byName;

  const DeviceEvent({required this.ts, required this.deviceId, required this.isOn, required this.by, this.byName = ''});

  factory DeviceEvent.fromMap(Map<String, dynamic> m) => DeviceEvent(
        ts: _time(m['ts']),
        deviceId: _str(m['deviceId']),
        isOn: m['isOn'] == true,
        by: _str(m['by'], 'user'),
        byName: _str(m['byName']),
      );
}

/// Alert written in the plant's voice (M5).
class AlertItem {
  final String id;
  final String greenhouseId;
  final String plantName;
  final String cropKey;
  final String param;
  final double value;
  final String message;
  final DateTime? ts;
  final bool read;

  const AlertItem({
    required this.id,
    required this.greenhouseId,
    required this.plantName,
    required this.cropKey,
    required this.param,
    required this.value,
    required this.message,
    required this.ts,
    required this.read,
  });

  factory AlertItem.fromMap(String id, Map<String, dynamic> m) => AlertItem(
        id: id,
        greenhouseId: _str(m['greenhouseId']),
        plantName: _str(m['plantName']),
        cropKey: _str(m['cropKey'], 'greens'),
        param: _str(m['param']),
        value: _num(m['value']),
        message: _str(m['message']),
        ts: _time(m['ts']),
        read: m['read'] == true,
      );
}
