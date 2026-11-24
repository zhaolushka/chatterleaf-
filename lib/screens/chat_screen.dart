import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/format.dart';
import '../logic/mood.dart';
import '../logic/plant_talk.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';

class _Entry {
  _Entry({required this.fromPlant, required this.text, required this.mood, this.actions = const []}) : time = DateTime.now();
  final bool fromPlant;
  final String text;
  final Mood mood;
  final List<PlantAction> actions;
  final DateTime time;
  bool actionsUsed = false;
}

/// Screen 4. Chat with the plant — Tamyr's own feature.
/// The plant answers from the bed's current data (lib/logic/plant_talk.dart)
/// and can ask for help with a button: [Water me], [Open window]…
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.greenhouseId});
  final String greenhouseId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _subs = <StreamSubscription<dynamic>>[];
  final _messages = <_Entry>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Greenhouse? _gh;
  Map<String, bool> _devices = {};
  bool _devicesLoaded = false;
  bool _typing = false;
  bool _greeted = false;

  @override
  void initState() {
    super.initState();
    _subs.add(greenhouseRepository.watchGreenhouse(widget.greenhouseId).listen((g) {
      setState(() => _gh = g);
      _greetOnce();
    }));
    _subs.add(greenhouseRepository.watchDevices(widget.greenhouseId).listen((list) {
      setState(() {
        _devices = {for (final d in list) d.id: d.isOn};
        _devicesLoaded = true;
      });
      _greetOnce();
    }));
    connectivity.addListener(_onConnectivity);
  }

  void _onConnectivity() => setState(() {});

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    connectivity.removeListener(_onConnectivity);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  PlantTalk get _talk => PlantTalk(greenhouse: _gh!, devices: _devices, online: connectivity.online);

  void _greetOnce() {
    if (_greeted || _gh == null || !_devicesLoaded) return;
    _greeted = true;
    _addPlant(_talk.greeting());
  }

  void _addPlant(PlantMessage m) {
    setState(() => _messages.add(_Entry(fromPlant: true, text: m.text, mood: _talk.mood, actions: m.actions)));
    _scrollDown();
  }

  void _addUser(String text) {
    setState(() => _messages.add(_Entry(fromPlant: false, text: text, mood: Mood.happy)));
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  /// The plant "types" for a moment, so the answer feels alive.
  Future<void> _answer(PlantMessage Function() build) async {
    setState(() => _typing = true);
    _scrollDown();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || _gh == null) return;
    setState(() => _typing = false);
    _addPlant(build());
  }

  void _send(String text) {
    final q = text.trim();
    if (q.isEmpty || _gh == null || _typing) return;
    _input.clear();
    _addUser(q);
    _answer(() => _talk.reply(q));
  }

  Future<void> _doAction(_Entry entry, PlantAction a) async {
    final g = _gh;
    if (g == null) return;
    setState(() => entry.actionsUsed = true);
    _addUser('✓ ${a.label}');
    final result = await greenhouseRepository.setDevice(g.id, a.deviceId, a.turnOn,
        byName: authRepository.currentUser?.displayName ?? '');
    if (!mounted) return;
    if (result == CommandResult.queuedOffline) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No connection. The command will be sent when the internet is back')));
    }
    _answer(() => _talk.afterAction(a));
  }

  @override
  Widget build(BuildContext context) {
    final g = _gh;
    final mood = g == null ? Mood.sleepy : moodOf(g, online: connectivity.online);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Row(children: [
              RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              if (g != null)
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.pastel(g.cropKey), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: PlantAvatar(cropKey: g.cropKey, mood: mood, size: 44, shadow: false),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: mood == Mood.sleepy ? AppColors.muted : AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 3),
                      ),
                    ),
                  ),
                ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g?.plantName ?? 'Chat', style: nunito(19, FontWeight.w900, spacing: -0.3)),
                  Text(_typing ? 'typing…' : moodLabel(mood),
                      style: nunito(12, FontWeight.w800, color: needsHelp(mood) ? AppColors.forMood(mood) : AppColors.green)),
                ]),
              ),
            ]),
          ),
          const OfflineBanner(),
          Expanded(
            child: g == null
                ? const Loading()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    itemCount: _messages.length + (_typing ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 40, bottom: 10),
                            child: SoftCard(
                              radius: 22,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Text('•••', style: nunito(16, FontWeight.w900, color: AppColors.muted)),
                            ),
                          ),
                        );
                      }
                      return _MessageView(entry: _messages[i], cropKey: g.cropKey, onAction: _doAction);
                    },
                  ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              children: [
                for (final q in PlantTalk.quickQuestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(19),
                        onTap: () => _send(q),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Text(q, style: nunito(13, FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: SoftCard(
              radius: 32,
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    style: nunito(15, FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: g == null ? 'Message' : 'Message ${g.plantName}…',
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Send',
                  child: Material(
                    color: AppColors.black,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _send(_input.text),
                      child: const SizedBox(width: 50, height: 50, child: Icon(Icons.send_rounded, color: AppColors.lime, size: 20)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.entry, required this.cropKey, required this.onAction});
  final _Entry entry;
  final String cropKey;
  final void Function(_Entry, PlantAction) onAction;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.74;
    final time = formatTime(entry.time);
    if (!entry.fromPlant) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: const BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(entry.text, style: nunito(15, FontWeight.w700, color: Colors.white, height: 1.4)),
            Text('$time ✓✓', style: nunito(10, FontWeight.w800, color: const Color(0xFFA9A2B6))),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.pastel(cropKey), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: PlantAvatar(cropKey: cropKey, mood: entry.mood, size: 28, shadow: false),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: AppColors.softShadow,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(entry.text, style: nunito(15, FontWeight.w700, height: 1.4)),
                Text(time, style: nunito(10, FontWeight.w800, color: AppColors.muted)),
              ]),
            ),
          ),
        ]),
        if (entry.actions.isNotEmpty && !entry.actionsUsed)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 8),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final a in entry.actions)
                Material(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => onAction(entry, a),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(a.label, style: nunito(14, FontWeight.w900)),
                        const SizedBox(width: 10),
                        const CircleAvatar(radius: 15, backgroundColor: AppColors.black, child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }
}
