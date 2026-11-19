import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/greenhouse_repository.dart';
import '../models/device.dart';
import '../models/greenhouse.dart';
import '../theme/app_colors.dart';
import '../widgets/mode_chip.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  IconData _icon(String type) {
    switch (type) {
      case 'irrigation':
        return Icons.opacity;
      case 'ventilation':
        return Icons.air;
      case 'lighting':
        return Icons.lightbulb_outline;
      case 'heating':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.device_hub_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GreenhouseRepository>();
    final offline = repo.isOffline;

    return StreamBuilder<Greenhouse?>(
      stream: repo.watchGreenhouse(),
      builder: (context, ghSnap) {
        final gh = ghSnap.data;
        return StreamBuilder<List<Device>>(
          stream: repo.watchDevices(),
          builder: (context, dSnap) {
            final devices = dSnap.data ?? const <Device>[];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Devices',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    ModeChip(
                      isAuto: gh?.isAuto ?? false,
                      onToggle: offline
                          ? null
                          : () {
                              final next =
                                  (gh?.isAuto ?? false) ? 'manual' : 'auto';
                              repo.setMode(next);
                            },
                    ),
                  ],
                ),
                if (gh?.isAuto == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Auto mode can override switches from live readings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                ...devices.map((d) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: SwitchListTile(
                      secondary: Icon(_icon(d.type), color: AppColors.primary),
                      title: Text(d.name),
                      subtitle: Text(
                        d.isOn
                            ? 'On · by ${d.changedBy}'
                            : 'Off · last by ${d.changedBy}',
                      ),
                      value: d.isOn,
                      onChanged: offline
                          ? null
                          : (v) => repo.setDevice(d.id, v, changedBy: 'user'),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
