import '../models/greenhouse_settings.dart';
import '../models/persona.dart';
import '../models/readings.dart';
import 'persona_engine.dart';

class PendingAlert {
  const PendingAlert({
    required this.parameter,
    required this.value,
    required this.message,
  });

  final String parameter;
  final double value;
  final String message;
}

/// M5: builds plant-voice alerts when readings leave their range.
class AlertService {
  AlertService({PersonaEngine? engine}) : _engine = engine ?? const PersonaEngine();

  final PersonaEngine _engine;

  List<PendingAlert> check({
    required Readings readings,
    required GreenhouseSettings settings,
    required Persona persona,
  }) {
    final out = <PendingAlert>[];

    void add(String parameter, double value, double min, double max,
        {bool lightOnly = false}) {
      final low = lightOnly ? value < min : value < min;
      final high = lightOnly ? false : value > max;
      if (!low && !high) return;
      out.add(
        PendingAlert(
          parameter: parameter,
          value: value,
          message: _engine.readingMessage(
            persona: persona,
            parameter: parameter,
            value: value,
            outOfRange: true,
            high: high,
          ),
        ),
      );
    }

    add('airTemp', readings.airTemp, settings.tempMin, settings.tempMax);
    add('airHumidity', readings.airHumidity, settings.humMin, settings.humMax);
    add('soilMoisture', readings.soilMoisture, settings.soilMin, settings.soilMax);
    add('light', readings.light, settings.lightMin, double.infinity,
        lightOnly: true);

    return out;
  }
}
