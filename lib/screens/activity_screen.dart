import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/format.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Activity log (Education track): who switched what and when.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.greenhouseId});
  final String greenhouseId;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late final Stream<List<DeviceEvent>> _stream = greenhouseRepository.watchEvents(widget.greenhouseId);

  static const _names = {'irrigation': 'Watering', 'window': 'Window', 'light': 'Light', 'heater': 'Heater'};
  static const _icons = {
    'irrigation': Icons.water_drop_rounded,
    'window': Icons.window_rounded,
    'light': Icons.lightbulb_rounded,
    'heater': Icons.local_fire_department_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const ScreenHeader(title: 'Activity log', subtitle: 'Who switched what'),
          Expanded(
            child: StreamBuilder<List<DeviceEvent>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) return ErrorMessage('Could not load the log.\n${snap.error}');
                if (!snap.hasData) return const Loading();
                final events = snap.data!;
                if (events.isEmpty) return const ErrorMessage('Nothing has been switched yet.');
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = events[i];
                    return SoftCard(
                      radius: 22,
                      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: e.isOn ? const Color(0xFFDFF2DC) : AppColors.field,
                          child: Icon(_icons[e.deviceId] ?? Icons.power_settings_new_rounded, size: 20, color: AppColors.ink),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${_names[e.deviceId] ?? e.deviceId} ${e.isOn ? 'on' : 'off'}', style: nunito(15, FontWeight.w900)),
                            Text(e.byName.isNotEmpty ? e.byName : byLabel(e.by), style: nunito(13, FontWeight.w700, color: AppColors.muted)),
                          ]),
                        ),
                        Text(formatDateTime(e.ts), style: nunito(12, FontWeight.w800, color: AppColors.muted)),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
