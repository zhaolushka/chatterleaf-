import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/format.dart';
import '../logic/mood.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';
import 'bed_screen.dart';

/// Screen 7. Alerts (M5): the plants call for help in their own voice.
/// Tapping an alert opens the right bed.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.uid});
  final String uid;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final Stream<List<AlertItem>> _stream = greenhouseRepository.watchAlerts(widget.uid);

  Mood _moodFor(AlertItem a) => a.param == 'soilMoisture' ? Mood.thirsty : (a.value < 15 ? Mood.cold : Mood.hot);

  void _open(AlertItem a) {
    if (!a.read) greenhouseRepository.markAlertRead(a.id);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BedScreen(greenhouseId: a.greenhouseId)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AlertItem>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return ErrorMessage('Could not load alerts.\n${snap.error}');
        if (!snap.hasData) return const Loading();
        final all = snap.data!;
        final now = DateTime.now();
        final today = all.where((a) => a.ts != null && a.ts!.year == now.year && a.ts!.month == now.month && a.ts!.day == now.day).toList();
        final earlier = all.where((a) => !today.contains(a)).toList();
        final unread = all.where((a) => !a.read).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(unread == 0 ? 'All read' : '$unread new', style: nunito(15, FontWeight.w700, color: AppColors.muted)),
                  Text('Alerts', style: nunito(34, FontWeight.w900, spacing: -0.8)),
                ]),
              ),
              if (unread > 0)
                TextButton(
                  onPressed: () => greenhouseRepository.markAllAlertsRead(widget.uid),
                  style: TextButton.styleFrom(backgroundColor: Colors.white, shape: const StadiumBorder()),
                  child: Text('Mark all read', style: nunito(13, FontWeight.w800)),
                ),
            ]),
            const SizedBox(height: 12),
            if (all.isEmpty) const ErrorMessage('No alerts — everyone is fine.'),
            if (today.isNotEmpty) ...[_label('TODAY'), for (final a in today) _row(a)],
            if (earlier.isNotEmpty) ...[_label('EARLIER'), for (final a in earlier) _row(a)],
          ],
        );
      },
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 0, 8),
        child: Text(t, style: nunito(13, FontWeight.w900, color: AppColors.muted, spacing: 0.5)),
      );

  Widget _row(AlertItem a) {
    final fresh = !a.read;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: fresh ? AppColors.pastel(a.cropKey) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => _open(a),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
            child: Row(children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(color: fresh ? Colors.white : AppColors.pastel(a.cropKey), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: PlantAvatar(cropKey: a.cropKey, mood: _moodFor(a), size: 48, shadow: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(a.plantName, style: nunito(16, FontWeight.w900)),
                    if (fresh) ...[
                      const SizedBox(width: 6),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                    ],
                    const Spacer(),
                    Text(timeAgo(a.ts), style: nunito(12, FontWeight.w800, color: AppColors.muted)),
                  ]),
                  Text(a.message, style: nunito(14, fresh ? FontWeight.w800 : FontWeight.w600, color: fresh ? AppColors.ink : AppColors.muted, height: 1.3)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
