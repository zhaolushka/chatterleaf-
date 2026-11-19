import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/auth_service.dart';
import '../data/connectivity_service.dart';
import '../data/greenhouse_repository.dart';
import '../models/greenhouse.dart';
import '../models/greenhouse_settings.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  GreenhouseSettings? _draft;
  String? _error;
  bool _busy = false;

  final _tempMin = TextEditingController();
  final _tempMax = TextEditingController();
  final _humMin = TextEditingController();
  final _humMax = TextEditingController();
  final _soilMin = TextEditingController();
  final _soilMax = TextEditingController();
  final _lightMin = TextEditingController();
  final _irrigation = TextEditingController();

  @override
  void dispose() {
    _tempMin.dispose();
    _tempMax.dispose();
    _humMin.dispose();
    _humMax.dispose();
    _soilMin.dispose();
    _soilMax.dispose();
    _lightMin.dispose();
    _irrigation.dispose();
    super.dispose();
  }

  void _hydrate(GreenhouseSettings s) {
    if (_draft != null) return;
    _draft = s;
    _tempMin.text = s.tempMin.toStringAsFixed(0);
    _tempMax.text = s.tempMax.toStringAsFixed(0);
    _humMin.text = s.humMin.toStringAsFixed(0);
    _humMax.text = s.humMax.toStringAsFixed(0);
    _soilMin.text = s.soilMin.toStringAsFixed(0);
    _soilMax.text = s.soilMax.toStringAsFixed(0);
    _lightMin.text = s.lightMin.toStringAsFixed(0);
    _irrigation.text = s.irrigationTime;
  }

  GreenhouseSettings _fromFields(GreenhouseSettings base) {
    double parse(TextEditingController c, double fallback) =>
        double.tryParse(c.text.trim()) ?? fallback;
    return base.copyWith(
      tempMin: parse(_tempMin, base.tempMin),
      tempMax: parse(_tempMax, base.tempMax),
      humMin: parse(_humMin, base.humMin),
      humMax: parse(_humMax, base.humMax),
      soilMin: parse(_soilMin, base.soilMin),
      soilMax: parse(_soilMax, base.soilMax),
      lightMin: parse(_lightMin, base.lightMin),
      irrigationTime: _irrigation.text.trim().isEmpty
          ? base.irrigationTime
          : _irrigation.text.trim(),
    );
  }

  Future<void> _save(GreenhouseRepository repo) async {
    final base = _draft ?? GreenhouseSettings.defaults();
    final next = _fromFields(base).copyWith(unit: base.unit);
    final err = GreenhouseSettings.validate(next);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.saveSettings(next);
      _draft = next;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GreenhouseRepository>();
    final connectivity = context.watch<ConnectivityService>();

    return StreamBuilder<GreenhouseSettings?>(
      stream: repo.watchSettings(),
      builder: (context, sSnap) {
        final settings = sSnap.data;
        if (settings != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _hydrate(settings);
          });
        }
        return StreamBuilder<Greenhouse?>(
          stream: repo.watchGreenhouse(),
          builder: (context, ghSnap) {
            final gh = ghSnap.data;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Thresholds',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _pair('Temp min / max (°C)', _tempMin, _tempMax),
                _pair('Humidity min / max (%)', _humMin, _humMax),
                _pair('Soil min / max (%)', _soilMin, _soilMax),
                TextField(
                  controller: _lightMin,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Light min (lux)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _irrigation,
                  decoration:
                      const InputDecoration(labelText: 'Irrigation time (HH:mm)'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Use Fahrenheit'),
                  value: (_draft ?? settings)?.unit == 'f',
                  onChanged: (v) {
                    setState(() {
                      final base = _draft ?? settings ?? GreenhouseSettings.defaults();
                      _draft = base.copyWith(unit: v ? 'f' : 'c');
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Plant persona',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Persona.values.map((p) {
                    final selected = gh?.persona == p;
                    return ChoiceChip(
                      label: Text(p.displayName),
                      selected: selected,
                      onSelected: repo.isOffline
                          ? null
                          : (_) => repo.setPersona(p),
                    );
                  }).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.alert,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy || repo.isOffline ? null : () => _save(repo),
                  child: Text(_busy ? 'Saving…' : 'Save settings'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Demo tools',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: repo.isOffline
                      ? null
                      : () async {
                          await repo.createDemoData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Created 7 days of history (incl. 45°C & 18% soil).',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.dataset_outlined),
                  label: const Text('Create demo data'),
                ),
                OutlinedButton.icon(
                  onPressed: repo.isOffline ? null : () => repo.simulateHotSpike(),
                  icon: const Icon(Icons.whatshot),
                  label: const Text('Simulate 45°C spike'),
                ),
                OutlinedButton.icon(
                  onPressed: repo.isOffline ? null : () => repo.simulateDrySoil(),
                  icon: const Icon(Icons.water_drop),
                  label: const Text('Simulate 18% soil'),
                ),
                SwitchListTile(
                  title: const Text('Mock offline (No connection)'),
                  subtitle: const Text('Toggle M8 without airplane mode'),
                  value: !connectivity.isOnline,
                  onChanged: (v) => connectivity.setOnline(!v),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => context.read<AuthService>().signOut(),
                  icon: const Icon(Icons.logout, color: AppColors.alert),
                  label: const Text(
                    'Log out',
                    style: TextStyle(color: AppColors.alert),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _pair(String label, TextEditingController a, TextEditingController b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: a,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '$label (min)'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: b,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'max'),
            ),
          ),
        ],
      ),
    );
  }
}
