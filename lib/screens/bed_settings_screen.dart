import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/crop_profiles.dart';
import '../logic/mood.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';

/// Bed settings (M7): crop profile, thresholds, light schedule, units.
/// Wrong values (for example −50 %) are rejected — see GreenhouseSettings.validate().
/// Saved thresholds are used by automation immediately.
class BedSettingsScreen extends StatefulWidget {
  const BedSettingsScreen({super.key, required this.greenhouseId});
  final String greenhouseId;

  @override
  State<BedSettingsScreen> createState() => _BedSettingsScreenState();
}

class _BedSettingsScreenState extends State<BedSettingsScreen> {
  static const _fields = [
    ('tempMin', 'Min temp, °C'),
    ('tempMax', 'Max temp, °C'),
    ('humidityMin', 'Min air humidity, %'),
    ('humidityMax', 'Max air humidity, %'),
    ('soilMin', 'Water when soil below, %'),
    ('irrigationMinutes', 'Watering time, min'),
    ('lightOnAt', 'Lights on (HH:MM)'),
    ('lightOffAt', 'Lights off (HH:MM)'),
  ];

  final _c = {for (final f in _fields) f.$1: TextEditingController()};
  Greenhouse? _g;
  String _units = 'C';
  String? _profile;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _load() async {
    final g = await greenhouseRepository.watchGreenhouse(widget.greenhouseId).first;
    if (!mounted || g == null) return;
    final s = g.settings;
    _c['tempMin']!.text = _n(s.tempMin);
    _c['tempMax']!.text = _n(s.tempMax);
    _c['humidityMin']!.text = _n(s.humidityMin);
    _c['humidityMax']!.text = _n(s.humidityMax);
    _c['soilMin']!.text = _n(s.soilMin);
    _c['irrigationMinutes']!.text = '${s.irrigationMinutes}';
    _c['lightOnAt']!.text = s.lightOnAt;
    _c['lightOffAt']!.text = s.lightOffAt;
    setState(() {
      _g = g;
      _units = s.units;
      _profile = g.cropKey;
    });
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyProfile(CropProfile p) {
    setState(() {
      _profile = p.key;
      _c['tempMin']!.text = _n(p.preset.tempMin);
      _c['tempMax']!.text = _n(p.preset.tempMax);
      _c['humidityMin']!.text = _n(p.preset.humidityMin);
      _c['humidityMax']!.text = _n(p.preset.humidityMax);
      _c['soilMin']!.text = _n(p.preset.soilMin);
      _error = null;
    });
  }

  double? _num(String key) => double.tryParse(_c[key]!.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final g = _g;
    if (g == null) return;
    setState(() => _error = null);
    for (final f in _fields.where((f) => !f.$1.startsWith('light'))) {
      if (_num(f.$1) == null) {
        setState(() => _error = '“${f.$2}” must be a number');
        return;
      }
    }
    final settings = GreenhouseSettings(
      tempMin: _num('tempMin')!,
      tempMax: _num('tempMax')!,
      humidityMin: _num('humidityMin')!,
      humidityMax: _num('humidityMax')!,
      soilMin: _num('soilMin')!,
      irrigationMinutes: _num('irrigationMinutes')!.round(),
      lightMin: g.settings.lightMin,
      lightOnAt: _c['lightOnAt']!.text.trim(),
      lightOffAt: _c['lightOffAt']!.text.trim(),
      units: _units,
    );
    final error = settings.validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      // Offline, Firestore saves later, so we don't wait longer than 5 seconds.
      await greenhouseRepository.updateSettings(g.id, settings).timeout(const Duration(seconds: 5), onTimeout: () {});
      messenger.showSnackBar(SnackBar(content: Text('Saved. ${g.plantName} will use the new thresholds right away.')));
      navigator.pop();
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _g;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          ScreenHeader(title: 'Settings', subtitle: g == null ? null : '${g.plantName} · ${g.name}'),
          const OfflineBanner(),
          Expanded(
            child: g == null
                ? const Loading()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                    children: [
                      Text('Crop profile', style: nunito(15, FontWeight.w900)),
                      const SizedBox(height: 8),
                      Row(children: [
                        for (final p in cropProfiles.values) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _applyProfile(p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.pastel(p.key),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: _profile == p.key ? AppColors.black : Colors.transparent, width: 3),
                                ),
                                child: Column(children: [
                                  PlantAvatar(cropKey: p.key, mood: Mood.happy, size: 46, shadow: false),
                                  Text(p.title, style: nunito(12, FontWeight.w900), overflow: TextOverflow.ellipsis),
                                  Text(p.idealTemp.replaceAll(' °C', '°'), style: nunito(11, FontWeight.w700, color: AppColors.muted)),
                                ]),
                              ),
                            ),
                          ),
                          if (p.key != cropProfiles.keys.last) const SizedBox(width: 8),
                        ],
                      ]),
                      const SizedBox(height: 14),
                      SoftCard(
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.0,
                          children: [
                            for (final f in _fields)
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f.$2, style: nunito(12, FontWeight.w800, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _c[f.$1],
                                  keyboardType: f.$1.startsWith('light')
                                      ? TextInputType.datetime
                                      : const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  style: nunito(17, FontWeight.w900),
                                  decoration: const InputDecoration(isDense: true),
                                ),
                              ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Text('Units', style: nunito(15, FontWeight.w900)),
                        const Spacer(),
                        SizedBox(
                          width: 170,
                          child: PillSegment<String>(
                            options: const [('C', '°C'), ('F', '°F')],
                            selected: _units,
                            onChanged: (v) => setState(() => _units = v),
                          ),
                        ),
                      ]),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFFFFE9E7), borderRadius: BorderRadius.circular(20)),
                          child: Text(_error!, style: nunito(14, FontWeight.w800, color: const Color(0xFFC62F35))),
                        ),
                      ],
                      const SizedBox(height: 22),
                      PillButton(label: 'Save', loading: _saving, onTap: _save),
                      const SizedBox(height: 10),
                      Center(
                        child: Text('Invalid values (e.g. −50 %) won’t be saved',
                            style: nunito(13, FontWeight.w700, color: AppColors.muted)),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}
