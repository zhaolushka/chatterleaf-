import '../models/persona.dart';

/// Rule-based plant voice — no AI / network calls.
class PersonaEngine {
  const PersonaEngine();

  String greeting(Persona persona) {
    switch (persona) {
      case Persona.tomatoDramaQueen:
        return "Hello? Finally. I've been waiting. Check my cards!";
      case Persona.basilChillOne:
        return 'Hey friend. Everything is chill for now.';
      case Persona.succulentZenMaster:
        return 'Welcome back. Breathe. The greenhouse is present.';
      case Persona.orchidDiva:
        return 'Darling, you returned. Appreciate the lighting, please.';
    }
  }

  String readingMessage({
    required Persona persona,
    required String parameter,
    required double value,
    required bool outOfRange,
    required bool high,
  }) {
    final unit = _unit(parameter);
    final pretty = _paramLabel(parameter);
    if (!outOfRange) {
      return _ok(persona, pretty, value, unit);
    }
    return high
        ? _tooHigh(persona, pretty, value, unit)
        : _tooLow(persona, pretty, value, unit);
  }

  String deviceConfirm({
    required Persona persona,
    required String deviceType,
    required bool isOn,
    required String changedBy,
  }) {
    final who = changedBy == 'auto' ? 'Auto mode' : 'You';
    final action = isOn ? 'on' : 'off';
    switch (deviceType) {
      case 'irrigation':
        if (isOn) {
          return switch (persona) {
            Persona.tomatoDramaQueen =>
              '$who watered me! Ahh, finally — thank you.',
            Persona.basilChillOne => 'Nice. Water on. Feeling hydrated.',
            Persona.succulentZenMaster =>
              'Moisture arrives. Balance returns. Water $action.',
            Persona.orchidDiva => 'Irrigation $action. Do not drown me, darling.',
          };
        }
        return 'Irrigation $action. Watching the soil now.';
      case 'ventilation':
        return isOn
            ? switch (persona) {
                Persona.tomatoDramaQueen =>
                  'Vents opened. Cooling down NOW. I was melting!',
                Persona.basilChillOne => 'Vents open. Fresh air — cool.',
                Persona.succulentZenMaster => 'Air flows. Heat softens.',
                Persona.orchidDiva => 'Ventilation $action. Much better.',
              }
            : 'Ventilation $action.';
      case 'lighting':
        return isOn
            ? switch (persona) {
                Persona.tomatoDramaQueen => 'Lights on! I need my spotlight.',
                Persona.basilChillOne => 'Lights on. Photosynthesis party.',
                Persona.succulentZenMaster => 'Light returns. Growth continues.',
                Persona.orchidDiva => 'Lighting $action. Flawless.',
              }
            : 'Lighting $action.';
      case 'heating':
        return isOn
            ? switch (persona) {
                Persona.tomatoDramaQueen =>
                  'Heat on! I was FREEZING in here.',
                Persona.basilChillOne => 'Heat on. Cozy vibes.',
                Persona.succulentZenMaster => 'Warmth rises. Comfort returns.',
                Persona.orchidDiva => 'Heating $action. Keep me pampered.',
              }
            : 'Heating $action.';
      default:
        return '$deviceType turned $action.';
    }
  }

  String _ok(Persona p, String pretty, double v, String unit) {
    switch (p) {
      case Persona.tomatoDramaQueen:
        return '$pretty is ${v.toStringAsFixed(0)}$unit. Acceptable… for now.';
      case Persona.basilChillOne:
        return '$pretty sits at ${v.toStringAsFixed(0)}$unit. All good.';
      case Persona.succulentZenMaster:
        return '$pretty: ${v.toStringAsFixed(0)}$unit. Harmony.';
      case Persona.orchidDiva:
        return '$pretty ${v.toStringAsFixed(0)}$unit — within my standards.';
    }
  }

  String _tooHigh(Persona p, String pretty, double v, String unit) {
    switch (p) {
      case Persona.tomatoDramaQueen:
        return "It's ${v.toStringAsFixed(0)}$unit $pretty and I am NOT okay.";
      case Persona.basilChillOne:
        return '$pretty hit ${v.toStringAsFixed(0)}$unit. A bit much, yeah?';
      case Persona.succulentZenMaster:
        return '$pretty rises to ${v.toStringAsFixed(0)}$unit. Seek coolness.';
      case Persona.orchidDiva:
        return '${v.toStringAsFixed(0)}$unit $pretty?! Absolutely unacceptable.';
    }
  }

  String _tooLow(Persona p, String pretty, double v, String unit) {
    switch (p) {
      case Persona.tomatoDramaQueen:
        return 'Only ${v.toStringAsFixed(0)}$unit $pretty?! Help meee.';
      case Persona.basilChillOne:
        return '$pretty down to ${v.toStringAsFixed(0)}$unit. Could use a boost.';
      case Persona.succulentZenMaster:
        return '$pretty at ${v.toStringAsFixed(0)}$unit. Patience… and action.';
      case Persona.orchidDiva:
        return '${v.toStringAsFixed(0)}$unit $pretty is beneath me. Fix it.';
    }
  }

  String _paramLabel(String parameter) {
    switch (parameter) {
      case 'airTemp':
        return 'temperature';
      case 'airHumidity':
        return 'humidity';
      case 'soilMoisture':
        return 'soil moisture';
      case 'light':
        return 'light';
      default:
        return parameter;
    }
  }

  String _unit(String parameter) {
    switch (parameter) {
      case 'airTemp':
        return '°C';
      case 'airHumidity':
      case 'soilMoisture':
        return '%';
      case 'light':
        return ' lux';
      default:
        return '';
    }
  }
}
