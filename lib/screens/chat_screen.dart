import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/greenhouse_repository.dart';
import '../models/chat_message.dart';
import '../models/greenhouse.dart';
import '../theme/app_colors.dart';
import '../widgets/plant_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(GreenhouseRepository repo) async {
    final text = _controller.text;
    _controller.clear();
    try {
      await repo.sendUserChat(text);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GreenhouseRepository>();

    return Column(
      children: [
        StreamBuilder<Greenhouse?>(
          stream: repo.watchGreenhouse(),
          builder: (context, ghSnap) {
            final name = ghSnap.data?.persona.displayName ?? 'Plant';
            return StreamBuilder<List<ChatMessage>>(
              stream: repo.watchChat(),
              builder: (context, snap) {
                final msgs = snap.data ?? const <ChatMessage>[];
                return Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) {
                      final m = msgs[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                          alignment: m.fromPlant
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: PlantMessageBubble(
                            text: m.text,
                            personaName: name,
                            fromPlant: m.fromPlant,
                            compact: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Say hi to your plant…',
                    ),
                    onSubmitted: (_) => _send(repo),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: repo.isOffline ? null : () => _send(repo),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
