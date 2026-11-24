import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/crop_profiles.dart';
import '../logic/format.dart';
import '../logic/mood.dart';
import '../logic/plant_talk.dart';
import '../logic/status.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';
import 'activity_screen.dart';
import 'bed_settings_screen.dart';
import 'chat_screen.dart';
import 'devices_screen.dart';
import 'history_screen.dart';

/// Screen 3. One bed (M2, M3, M4): the character with its line, 4 gauges,
/// the action the plant asks for, and the Manual/Auto switch.
class BedScreen extends StatefulWidget {
  const BedScreen({super.key, required this.greenhouseId});
  final String greenhouseId;

  @override
  State<BedScreen> createState() => _BedScreenState();
}

class _BedScreenState extends State<BedScreen> {
  late final Stream<Greenhouse?> _bed = greenhouseRepository.watchGreenhouse(widget.greenhouseId);
  StreamSubscription<List<Device>>? _devSub;
  Map<String, bool> _devices = {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _devSub = greenhouseRepository
        .watchDevices(widget.greenhouseId)
        .listen((list) => setState(() => _devices = {for (final d in list) d.id: d.isOn}));
  }

  @override
  void dispose() {
    _devSub?.cancel();
    super.dispose();
  }

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _doAction(Greenhouse g, PlantAction a) async {
    setState(() => _sending = true);
    final user = authRepository.currentUser;
    final result = await greenhouseRepository.setDevice(g.id, a.deviceId, a.turnOn, byName: user?.displayName ?? '');
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result == CommandResult.sent
          ? '${g.plantName}: ${PlantTalk(greenhouse: g).afterAction(a).text}'
          : 'No connection. The command will be sent when the internet is back'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: connectivity,
          builder: (context, _) => StreamBuilder<Greenhouse?>(
            stream: _bed,
            builder: (context, snap) {
              final g = snap.data;
              return Column(children: [
                ScreenHeader(
                  title: g?.plantName ?? 'Bed',
                  subtitle: g == null ? null : '${profileFor(g.cropKey).title} · ${g.name}',
                  right: RoundIconButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Bed settings',
                    onTap: g == null ? null : () => _open(BedSettingsScreen(greenhouseId: g.id)),
                  ),
                ),
                const OfflineBanner(),
                Expanded(child: _body(snap, g)),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _body(AsyncSnapshot<Greenhouse?> snap, Greenhouse? g) {
    if (snap.hasError) return ErrorMessage('Could not load the bed.\n${snap.error}');
    if (snap.connectionState == ConnectionState.waiting) return const Loading();
    if (g == null) return const ErrorMessage('Bed not found');

    final online = connectivity.online;
    final mood = moodOf(g, online: online);
    // The line changes once a minute, not on every data update.
    final talk = PlantTalk(greenhouse: g, devices: _devices, online: online, random: Random(g.id.hashCode ^ DateTime.now().minute));
    final actions = talk.suggestedActions();
    final r = g.current, s = g.settings;
    final problems = findProblems(r, s).map((p) => p.param).toSet();
    final (t, tu) = tempParts(r.airTemp, s.units);
    final tempPct = ((r.airTemp - (s.tempMin - 10)) / ((s.tempMax + 10) - (s.tempMin - 10)) * 100);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // Hero card: character on a soft gradient.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.pastel(g.cropKey), Color.lerp(AppColors.pastel(g.cropKey), Colors.white, 0.5)!],
            ),
          ),
          child: Column(children: [
            Row(children: [
              StatusChip(
                label: moodLabel(mood),
                background: needsHelp(mood) ? AppColors.forMood(mood) : Colors.white,
                foreground: needsHelp(mood) && mood != Mood.thirsty ? Colors.white : AppColors.ink,
                dot: needsHelp(mood) ? null : AppColors.forMood(mood),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => greenhouseRepository.setMode(g.id, g.isAuto ? 'manual' : 'auto'),
                child: StatusChip(
                  label: g.isAuto ? 'Auto mode' : 'Manual mode',
                  icon: g.isAuto ? Icons.smart_toy_outlined : Icons.pan_tool_alt_outlined,
                  background: g.isAuto ? AppColors.lime : const Color(0xCCFFFFFF),
                ),
              ),
            ]),
            GlowAvatar(cropKey: g.cropKey, mood: mood, size: 160, animate: true),
            Transform.translate(offset: const Offset(0, -6), child: SpeechBubble(text: '“${talk.statusLine()}”')),
          ]),
        ),
        const SizedBox(height: 14),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RingGauge(percent: tempPct, color: problems.contains('airTemp') ? AppColors.red : AppColors.green, value: t, unit: tu, label: 'Temp'),
              RingGauge(percent: r.soilMoisture, color: problems.contains('soilMoisture') ? AppColors.yellow : AppColors.sky, value: '${r.soilMoisture.round()}', unit: '%', label: 'Soil'),
              RingGauge(percent: r.airHumidity, color: const Color(0xFF8FC8FA), value: '${r.airHumidity.round()}', unit: '%', label: 'Air'),
              RingGauge(
                  percent: min(100.0, r.light / 200),
                  color: AppColors.yellow,
                  value: r.light >= 1000 ? (r.light / 1000).toStringAsFixed(0) : '${r.light.round()}',
                  unit: r.light >= 1000 ? 'k lx' : 'lx',
                  label: 'Light'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            isStale(r) ? 'Updated ${timeAgo(r.updatedAt)} — no new data' : 'Updated ${timeAgo(r.updatedAt)}',
            style: nunito(12, FontWeight.w700, color: isStale(r) ? AppColors.red : AppColors.muted),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: actions.isNotEmpty
                ? PillButton(label: actions.first.label, loading: _sending, onTap: () => _doAction(g, actions.first))
                : PillButton(label: 'Devices', icon: Icons.toggle_on_outlined, onTap: () => _open(DevicesScreen(greenhouseId: g.id))),
          ),
          const SizedBox(width: 10),
          RoundIconButton(icon: Icons.chat_bubble_outline_rounded, tooltip: 'Chat with ${g.plantName}', size: 62, onTap: () => _open(ChatScreen(greenhouseId: g.id))),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Link(icon: Icons.toggle_on_outlined, label: 'Devices', onTap: () => _open(DevicesScreen(greenhouseId: g.id))),
          _Link(icon: Icons.insights_rounded, label: 'Mood diary', onTap: () => _open(HistoryScreen(greenhouseId: g.id))),
          _Link(icon: Icons.menu_book_outlined, label: 'Log', onTap: () => _open(ActivityScreen(greenhouseId: g.id))),
        ]),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: AppColors.muted),
        label: Text(label, style: nunito(14, FontWeight.w800, color: AppColors.muted)),
      );
}
