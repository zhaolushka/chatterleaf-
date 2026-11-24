import 'dart:math';

// "Normal day" model of a greenhouse bed. Same idea as simulator/model.js:
// warm afternoons, cool nights, sun from 6:00 to 20:00, soil dries between waterings.

class DayProfile {
  final double baseTemp;
  final double tempAmp;
  final double baseHumidity;
  const DayProfile(this.baseTemp, this.tempAmp, this.baseHumidity);

  /// Profile from thresholds: middle of the range, swing = a quarter of it.
  factory DayProfile.fromRange(double tMin, double tMax, double hMin, double hMax) =>
      DayProfile((tMin + tMax) / 2, (tMax - tMin) / 4, (hMin + hMax) / 2);
}

double _round1(double v) => (v * 10).roundToDouble() / 10;
double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

class SimReading {
  final double airTemp, airHumidity, soilMoisture, light;
  const SimReading(this.airTemp, this.airHumidity, this.soilMoisture, this.light);
}

SimReading normalReading(DateTime t, DayProfile p, Random rnd) {
  final h = t.hour + t.minute / 60;
  final wave = sin(2 * pi * (h - 9) / 24); // peak around 15:00
  double noise(double size) => (rnd.nextDouble() - 0.5) * 2 * size;

  final temp = p.baseTemp + p.tempAmp * wave + noise(0.6);
  final hum = p.baseHumidity - 12 * wave + noise(2);
  final light = (h >= 6 && h <= 20) ? 22000 * sin(pi * (h - 6) / 14) * (0.75 + 0.25 * rnd.nextDouble()) : 0.0;
  final sinceWatering = h >= 19 ? h - 19 : (h >= 7 ? h - 7 : h + 5);
  final soil = 68 - 1.6 * sinceWatering + noise(1);

  return SimReading(
    _round1(_clamp(temp, -20, 60)),
    _round1(_clamp(hum, 5, 100)),
    _round1(_clamp(soil, 0, 100)),
    max(0, light).roundToDouble(),
  );
}

double round1(double v) => _round1(v);
double clampD(double v, double lo, double hi) => _clamp(v, lo, hi);
