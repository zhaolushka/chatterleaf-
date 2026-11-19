import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/greenhouse_repository.dart';
import '../models/greenhouse.dart';
import '../models/greenhouse_settings.dart';
import '../models/readings.dart';
import '../theme/app_colors.dart';
import '../widgets/mode_chip.dart';
import '../widgets/plant_message_bubble.dart';
import '../widgets/reading_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onOpenAlerts});

  final VoidCallback? onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GreenhouseRepository>();

    return StreamBuilder<Greenhouse?>(
      stream: repo.watchGreenhouse(),
      builder: (context, ghSnap) {
        final gh = ghSnap.data;
        return StreamBuilder<Readings?>(
          stream: repo.watchReadings(),
          builder: (context, rSnap) {
            return StreamBuilder<GreenhouseSettings?>(
              stream: repo.watchSettings(),
              builder: (context, sSnap) {
                final readings = rSnap.data;
                final settings = sSnap.data ?? GreenhouseSettings.defaults();
                final offline = repo.isOffline;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            gh?.name ?? 'Greenhouse',
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
                    const SizedBox(height: 12),
                    StreamBuilder(
                      stream: repo.watchLatestPlantMessage(),
                      builder: (context, msgSnap) {
                        final msg = msgSnap.data;
                        if (msg == null) {
                          return PlantMessageBubble(
                            text: 'Waiting for the first plant message…',
                            personaName: gh?.persona.shortName ?? 'Plant',
                            compact: true,
                          );
                        }
                        return GestureDetector(
                          onTap: onOpenAlerts,
                          child: PlantMessageBubble(
                            text: msg.text,
                            personaName: gh?.persona.displayName ?? 'Plant',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (readings == null)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        children: [
                          ReadingCard(
                            label: 'Air temperature',
                            valueText: _temp(readings.airTemp, settings),
                            icon: Icons.thermostat,
                            statusColor: AppColors.statusFor(
                              value: readings.airTemp,
                              min: settings.tempMin,
                              max: settings.tempMax,
                            ),
                            offline: offline,
                          ),
                          ReadingCard(
                            label: 'Air humidity',
                            valueText:
                                '${readings.airHumidity.toStringAsFixed(0)}%',
                            icon: Icons.water_drop_outlined,
                            statusColor: AppColors.statusFor(
                              value: readings.airHumidity,
                              min: settings.humMin,
                              max: settings.humMax,
                            ),
                            offline: offline,
                          ),
                          ReadingCard(
                            label: 'Soil moisture',
                            valueText:
                                '${readings.soilMoisture.toStringAsFixed(0)}%',
                            icon: Icons.grass,
                            statusColor: AppColors.statusFor(
                              value: readings.soilMoisture,
                              min: settings.soilMin,
                              max: settings.soilMax,
                            ),
                            offline: offline,
                          ),
                          ReadingCard(
                            label: 'Light',
                            valueText:
                                '${readings.light.toStringAsFixed(0)} lux',
                            icon: Icons.wb_sunny_outlined,
                            statusColor: AppColors.statusFor(
                              value: readings.light,
                              min: settings.lightMin,
                              max: settings.lightMin,
                              lightOnly: true,
                            ),
                            offline: offline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Last update: ${DateFormat.Hm().add_MMMd().format(readings.updatedAt)}'
                        '${offline ? ' (cached)' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _temp(double celsius, GreenhouseSettings s) {
    if (s.isCelsius) return '${celsius.toStringAsFixed(1)}°C';
    final f = celsius * 9 / 5 + 32;
    return '${f.toStringAsFixed(1)}°F';
  }
}
