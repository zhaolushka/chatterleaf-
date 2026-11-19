import '../models/device.dart';
import '../models/greenhouse_settings.dart';
import '../models/readings.dart';

class AutomationAction {
  const AutomationAction({
    required this.deviceId,
    required this.turnOn,
    required this.reason,
  });

  final String deviceId;
  final bool turnOn;
  final String reason;
}

/// M4: evaluates Auto-mode rules against current readings + thresholds.
class AutomationService {
  const AutomationService();

  /// Returns desired device states while mode is auto.
  List<AutomationAction> evaluate({
    required Readings readings,
    required GreenhouseSettings settings,
    required List<Device> devices,
  }) {
    final byId = {for (final d in devices) d.id: d};
    final actions = <AutomationAction>[];

    void want(String id, bool on, String reason) {
      final d = byId[id];
      if (d == null) return;
      if (d.isOn == on) return;
      actions.add(AutomationAction(deviceId: id, turnOn: on, reason: reason));
    }

    // Soil below minimum → irrigation on; otherwise off when auto-managed.
    if (readings.soilMoisture < settings.soilMin) {
      want('irrigation', true, 'Soil below minimum');
    } else if (readings.soilMoisture >= settings.soilMin) {
      want('irrigation', false, 'Soil OK');
    }

    // Temp above max → ventilation on; below min → heating on.
    if (readings.airTemp > settings.tempMax) {
      want('ventilation', true, 'Temperature above maximum');
      want('heating', false, 'Too hot for heating');
    } else if (readings.airTemp < settings.tempMin) {
      want('heating', true, 'Temperature below minimum');
      want('ventilation', false, 'Too cold for vents');
    } else {
      want('ventilation', false, 'Temperature OK');
      want('heating', false, 'Temperature OK');
    }

    // Light below minimum → lighting on.
    if (readings.light < settings.lightMin) {
      want('lighting', true, 'Light below minimum');
    } else {
      want('lighting', false, 'Light OK');
    }

    return actions;
  }
}
