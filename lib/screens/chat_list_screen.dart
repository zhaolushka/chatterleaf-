import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/mood.dart';
import '../logic/plant_talk.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';
import 'chat_screen.dart';

/// "Chat" tab: pick a plant to talk to.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, required this.uid});
  final String uid;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final Stream<List<Greenhouse>> _stream = greenhouseRepository.watchMyGreenhouses(widget.uid);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: connectivity,
      builder: (context, _) => StreamBuilder<List<Greenhouse>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return ErrorMessage('Could not load the plants.\n${snap.error}');
          if (!snap.hasData) return const Loading();
          final online = connectivity.online;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              Text('Talk to a plant', style: nunito(34, FontWeight.w900, spacing: -0.8)),
              const SizedBox(height: 4),
              Text('Ask how they feel, if they are thirsty and why they need light.',
                  style: nunito(14, FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 16),
              for (final g in snap.data!) ...[
                Material(
                  color: AppColors.pastel(g.cropKey),
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(greenhouseId: g.id))),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                      child: Row(children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: PlantAvatar(cropKey: g.cropKey, mood: moodOf(g, online: online), size: 54, shadow: false),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(g.plantName, style: nunito(17, FontWeight.w900)),
                            Text(PlantTalk(greenhouse: g, online: online).statusLine(),
                                maxLines: 2, overflow: TextOverflow.ellipsis, style: nunito(13, FontWeight.w700, color: AppColors.muted)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        const CircleAvatar(radius: 19, backgroundColor: AppColors.black, child: Icon(Icons.chat_bubble_rounded, size: 18, color: AppColors.lime)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}
