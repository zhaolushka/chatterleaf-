
import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/format.dart';
import '../logic/mood.dart';
import '../logic/plant_talk.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';

/// Screen 5. Devices (M3) + automatic mode switch (M4).
/// A switch shows the state FROM THE DATABASE: it flips when the write is confirmed.
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, required this.greenhouseId});
  final String greenhouseId;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late final Stream<List<Device>> _devices = greenhouseRepository.watchDevices(widget.greenhouseId);
  late final Stream<Greenhouse?> _bed = greenhouseRepository.watchGreenhouse(widget.greenhouseId);
  final Set<String> _sending = {};

  static const _meta = {
    'irrigation': (Icons.water_drop_rounded, Color(0xFFE3EEFF), PlantAction.water),
    'window': (Icons.window_rounded, Color(0xFFDFF2DC), PlantAction.openWindow),
    'light': (Icons.lightbulb_rounded, Color(0xFFFFF2CC), PlantAction.lightOn),
    'heater': (Icons.local_fire_department_rounded, Color(0xFFFFE3DD), PlantAction.heaterOn),
  };

  Future<void> _toggle(Greenhouse g, Device d, bool on) async {
    setState(() => _sending.add(d.id));
    final messenger = ScaffoldMessenger.of(context);
    final result = await greenhouseRepository.setDevice(g.id, d.id, on, byName: authRepository.currentUser?.displayName ?? '');
    if (!mounted) return;
    setState(() => _sending.remove(d.id));
    if (result == CommandResult.queuedOffline) {
      messenger.showSnackBar(SnackBar(content: Text('No connection. “${d.name}” will switch when the internet is back')));
    } else if (on && _meta[d.id] != null) {
      messenger.showSnackBar(SnackBar(content: Text('${g.plantName}: ${PlantTalk(greenhouse: g).afterAction(_meta[d.id]!.$3).text}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Greenhouse?>(
          stream: _bed,
          builder: (context, bedSnap) {
            final g = bedSnap.data;
            return Column(children: [
              ScreenHeader(title: 'Devices', subtitle: g == null ? null : '${g.plantName} · ${g.name}'),
              const OfflineBanner(),
              Expanded(
                child: g == null
                    ? const Loading()
                    : StreamBuilder<List<Device>>(
                        stream: _devices,
                        builder: (context, snap) {
                          if (snap.hasError) return ErrorMessage('Could not load devices.\n${snap.error}');
                          if (!snap.hasData) return const Loading();
                          final devices = snap.data!;
                          final mood = moodOf(g, online: connectivity.online);
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                            children: [
                              Container(
                                padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
                                decoration: BoxDecoration(color: AppColors.pastel(g.cropKey), borderRadius: BorderRadius.circular(30)),
                                child: Row(children: [
                                  GlowAvatar(cropKey: g.cropKey, mood: mood, size: 76),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(PlantTalk(greenhouse: g, online: connectivity.online).statusLine(),
                                        style: nunito(15, FontWeight.w800, height: 1.35)),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 14),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.95,
                                children: [for (final d in devices) _tile(g, d)],
                              ),
                              const SizedBox(height: 14),
                              SoftCard(
                                radius: 26,
                                child: Row(children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Auto mode', style: nunito(16, FontWeight.w900)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${g.plantName} opens the window above ${formatTemp(g.settings.tempMax, g.settings.units)} '
                                        'and waters itself when soil drops below ${g.settings.soilMin.round()} %',
                                        style: nunito(13, FontWeight.w700, color: AppColors.muted, height: 1.35),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(width: 12),
                                  PillSwitch(
                                    label: 'Auto mode',
                                    value: g.isAuto,
                                    onChanged: (v) => greenhouseRepository.setMode(g.id, v ? 'auto' : 'manual'),
                                  ),
                                ]),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _tile(Greenhouse g, Device d) {
    final meta = _meta[d.id];
    final tint = meta?.$2 ?? const Color(0xFFEDE6D6);
    final sending = _sending.contains(d.id);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: d.isOn ? tint : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: d.isOn ? null : AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: d.isOn ? Colors.white : tint, shape: BoxShape.circle),
              child: Icon(meta?.$1 ?? Icons.power_settings_new_rounded, color: AppColors.ink),
            ),
            const Spacer(),
            PillSwitch(label: d.name, value: d.isOn, onChanged: sending ? null : (v) => _toggle(g, d, v)),
          ]),
          const Spacer(),
          Text(d.name, style: nunito(19, FontWeight.w900)),
          Text(sending ? 'Sending…' : (d.isOn ? 'On' : 'Off'),
              style: nunito(14, FontWeight.w800, color: d.isOn ? AppColors.green : AppColors.muted)),
          Text('${byLabel(d.changedBy)} · ${timeAgo(d.changedAt)}', style: nunito(12, FontWeight.w700, color: AppColors.muted)),
        ],
      ),
    );
  }
}
