import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/crop_profiles.dart';
import '../logic/format.dart';
import '../logic/mood.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';
import 'bed_screen.dart';

/// Screen 2. Our beds (M2). Scenario 1: understand in 5 seconds whether all is
/// fine — by the plants' faces and the black "need help" card.
class GardensScreen extends StatefulWidget {
  const GardensScreen({super.key, required this.user, required this.unread, required this.onOpenAlerts});
  final AppUser user;
  final int unread;
  final VoidCallback onOpenAlerts;

  @override
  State<GardensScreen> createState() => _GardensScreenState();
}

class _GardensScreenState extends State<GardensScreen> {
  late final Stream<List<Greenhouse>> _stream = greenhouseRepository.watchMyGreenhouses(widget.user.uid);

  void _open(Greenhouse g) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BedScreen(greenhouseId: g.id)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) => StreamBuilder<List<Greenhouse>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return ErrorMessage('Could not load the beds.\n${snap.error}');
          if (!snap.hasData) return const Loading();
          final beds = snap.data!;
          final online = connectivity.online;
          final needHelp = beds.where((g) => needsHelp(moodOf(g, online: online))).toList();
          final columns = MediaQuery.sizeOf(context).width > 700 ? 4 : 2;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                sliver: SliverList.list(children: [
                  Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const PlantAvatar(cropKey: 'greens', mood: Mood.happy, size: 38, shadow: false),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Sälem,', style: nunito(13, FontWeight.w700, color: AppColors.muted)),
                        Text(widget.user.displayName, style: nunito(15, FontWeight.w900), overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    RoundIconButton(icon: Icons.notifications_none_rounded, tooltip: 'Alerts', dot: widget.unread > 0, onTap: widget.onOpenAlerts),
                  ]),
                  const SizedBox(height: 16),
                  Text('Our beds', style: nunito(36, FontWeight.w900, spacing: -1, height: 1)),
                  const SizedBox(height: 6),
                  Text('${beds.isEmpty ? '' : beds.first.place} · updated ${timeAgo(beds.isEmpty ? null : beds.first.current.updatedAt)}',
                      style: nunito(14, FontWeight.w700, color: AppColors.muted)),
                  const SizedBox(height: 16),
                  if (beds.isEmpty)
                    const ErrorMessage('No beds yet. In Firebase mode run the simulator: npm run seed')
                  else if (needHelp.isNotEmpty)
                    _HelpCard(beds: needHelp, online: online, onTap: () => _open(needHelp.first))
                  else
                    _AllGoodCard(count: beds.length, online: online),
                ]),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverGrid.count(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.74,
                  children: [for (final g in beds) _BedTile(greenhouse: g, online: online, onTap: () => _open(g))],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.beds, required this.online, required this.onTap});
  final List<Greenhouse> beds;
  final bool online;
  final VoidCallback onTap;

  String _why(Greenhouse g) => switch (moodOf(g, online: online)) {
        Mood.hot => '${g.plantName} is hot',
        Mood.cold => '${g.plantName} is cold',
        Mood.thirsty => '${g.plantName} is thirsty',
        _ => g.plantName,
      };

  @override
  Widget build(BuildContext context) {
    final n = beds.length;
    final shown = n.clamp(1, 3).toInt();
    return Material(
      color: AppColors.black,
      borderRadius: BorderRadius.circular(30),
      elevation: 10,
      shadowColor: const Color(0x66211D26),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(children: [
            SizedBox(
              width: 36.0 * shown + 12,
              height: 48,
              child: Stack(children: [
                for (var i = 0; i < shown; i++)
                  Positioned(
                    left: i * 36.0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.pastel(beds[i].cropKey),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: PlantAvatar(cropKey: beds[i].cropKey, mood: moodOf(beds[i], online: online), size: 38, shadow: false),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n == 1 ? '1 friend needs help' : '$n friends need help', style: nunito(16, FontWeight.w900, color: Colors.white)),
                Text(beds.map(_why).join(' · '),
                    style: nunito(12, FontWeight.w700, color: const Color(0xFFBDB6C9)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const ArrowCircle(),
          ]),
        ),
      ),
    );
  }
}

class _AllGoodCard extends StatelessWidget {
  const _AllGoodCard({required this.count, required this.online});
  final int count;
  final bool online;

  @override
  Widget build(BuildContext context) => SoftCard(
        color: online ? AppColors.lime : const Color(0xFFE3DDD1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Icon(online ? Icons.sentiment_very_satisfied_rounded : Icons.bedtime_outlined, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(online ? 'All $count friends are happy!' : 'No connection — the plants are asleep',
                style: nunito(16, FontWeight.w900)),
          ),
        ]),
      );
}

class _BedTile extends StatelessWidget {
  const _BedTile({required this.greenhouse, required this.online, required this.onTap});
  final Greenhouse greenhouse;
  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = greenhouse;
    final mood = moodOf(g, online: online);
    final (t, u) = tempParts(g.current.airTemp, g.settings.units);
    final soil = g.current.soilMoisture.clamp(0, 100).toDouble();
    return Material(
      color: AppColors.pastel(g.cropKey),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                StatusChip(label: moodLabel(mood), dot: AppColors.forMood(mood), background: const Color(0xBFFFFFFF)),
                const Spacer(),
                BigNumber(t, u, size: 15),
              ]),
              Expanded(child: Center(child: FittedBox(child: GlowAvatar(cropKey: g.cropKey, mood: mood, size: 88)))),
              Text(g.plantName, style: nunito(19, FontWeight.w900, spacing: -0.3)),
              Text('${profileFor(g.cropKey).title} · ${g.name}', style: nunito(12, FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF4D8FD6)),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: soil / 100,
                      minHeight: 6,
                      color: AppColors.sky,
                      backgroundColor: const Color(0x14211D26),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${soil.round()}%', style: nunito(11, FontWeight.w900)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
