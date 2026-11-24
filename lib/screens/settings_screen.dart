import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/crop_profiles.dart';
import '../logic/mood.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';
import 'bed_settings_screen.dart';

/// Screen 8. Settings tab: account, beds (thresholds), demo tools, sign out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.user});
  final AppUser user;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Stream<List<Greenhouse>> _stream = greenhouseRepository.watchMyGreenhouses(widget.user.uid);

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: nunito(20, FontWeight.w900)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) await authRepository.signOut();
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Greenhouse>>(
      stream: _stream,
      builder: (context, snap) {
        final beds = snap.data ?? const <Greenhouse>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            Text('Settings', style: nunito(34, FontWeight.w900, spacing: -0.8)),
            const SizedBox(height: 14),
            SoftCard(
              child: Row(children: [
                const CircleAvatar(radius: 24, backgroundColor: AppColors.lime, child: Icon(Icons.person_rounded, color: AppColors.ink)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.user.displayName, style: nunito(16, FontWeight.w900)),
                    Text(widget.user.email, style: nunito(13, FontWeight.w700, color: AppColors.muted)),
                  ]),
                ),
                StatusChip(label: kUseFirebase ? 'Firebase' : 'Demo mode', background: AppColors.field),
              ]),
            ),
            const SizedBox(height: 18),
            Text('Beds & thresholds', style: nunito(17, FontWeight.w900)),
            const SizedBox(height: 10),
            for (final g in beds) ...[
              Material(
                color: AppColors.pastel(g.cropKey),
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BedSettingsScreen(greenhouseId: g.id))),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                    child: Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: PlantAvatar(cropKey: g.cropKey, mood: Mood.happy, size: 44, shadow: false),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${g.plantName} · ${g.name}', style: nunito(16, FontWeight.w900)),
                          Text('${profileFor(g.cropKey).title} · ${g.settings.tempMin.round()}–${g.settings.tempMax.round()} °C · soil ≥ ${g.settings.soilMin.round()} %',
                              style: nunito(12, FontWeight.w700, color: AppColors.muted)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (demoBackend != null) ...[
              const SizedBox(height: 8),
              Text('Demo tools', style: nunito(17, FontWeight.w900)),
              Text('For the defense: trigger the stress-test scenarios without Firebase.',
                  style: nunito(13, FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 10),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  if (beds.isNotEmpty)
                    _DemoTile(
                      icon: Icons.thermostat_rounded,
                      title: 'Heat wave: ${beds.first.plantName} → 45 °C',
                      onTap: () {
                        demoBackend!.demoHeatWave(beds.first.id);
                        _toast('${beds.first.plantName} is now at 45 °C');
                      },
                    ),
                  if (beds.length > 1)
                    _DemoTile(
                      icon: Icons.water_drop_outlined,
                      title: 'Dry soil: ${beds[1].plantName} → 18 %',
                      onTap: () {
                        demoBackend!.demoDrySoil(beds[1].id);
                        _toast('${beds[1].plantName}’s soil is now at 18 %');
                      },
                    ),
                  ListenableBuilder(
                    listenable: connectivity,
                    builder: (context, _) => ListTile(
                      leading: const Icon(Icons.wifi_off_rounded, color: AppColors.ink),
                      title: Text('Simulate no internet', style: nunito(15, FontWeight.w800)),
                      trailing: PillSwitch(
                        label: 'Simulate no internet',
                        value: connectivity.simulatedOffline,
                        onChanged: connectivity.setSimulatedOffline,
                      ),
                    ),
                  ),
                  _DemoTile(
                    icon: Icons.refresh_rounded,
                    title: 'Reset demo data',
                    onTap: () {
                      demoBackend!.reset();
                      _toast('Demo data restored');
                    },
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 22),
            PillButton(label: 'Sign out', icon: Icons.logout_rounded, onTap: _signOut),
          ],
        );
      },
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.ink),
        title: Text(title, style: nunito(15, FontWeight.w800)),
        trailing: const Icon(Icons.play_circle_fill_rounded, color: AppColors.limeDark, size: 30),
        onTap: onTap,
      );
}
