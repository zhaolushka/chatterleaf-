import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/greenhouse_repository.dart';
import '../models/alert.dart';
import '../theme/app_colors.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GreenhouseRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: StreamBuilder<List<AlertItem>>(
        stream: repo.watchAlerts(),
        builder: (context, snap) {
          final alerts = snap.data ?? const <AlertItem>[];
          if (alerts.isEmpty) {
            return const Center(
              child: Text('No alerts yet. Simulate a spike from Settings.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = alerts[i];
              return Card(
                color: a.read
                    ? Colors.white
                    : AppColors.alert.withValues(alpha: 0.06),
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: a.read ? AppColors.muted : AppColors.alert,
                  ),
                  title: Text(
                    a.message,
                    style: TextStyle(
                      fontWeight:
                          a.read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${a.parameter} · ${a.value.toStringAsFixed(1)} · '
                    '${DateFormat.MMMd().add_Hm().format(a.ts)}',
                  ),
                  onTap: () async {
                    await repo.markAlertRead(a.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
