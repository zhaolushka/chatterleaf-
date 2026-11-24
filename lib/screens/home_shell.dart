import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/alert_service.dart';
import '../data/automation_service.dart';
import '../data/data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'alerts_screen.dart';
import 'bed_screen.dart';
import 'chat_list_screen.dart';
import 'gardens_screen.dart';
import 'settings_screen.dart';

/// App frame after sign-in: 4 tabs, floating pill navigation, "No connection" bar.
/// Starts automation (M4) and alerts (M5) for this user.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});
  final AppUser user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  late final AutomationService _automation = AutomationService(widget.user.uid);
  late final AlertService _alerts = AlertService(widget.user.uid);
  StreamSubscription<List<AlertItem>>? _alertSub;
  final Set<String> _seenAlerts = {};
  bool _firstAlertBatch = true;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _automation.start();
    _alerts.start();
    _alertSub = greenhouseRepository.watchAlerts(widget.user.uid).listen(_onAlerts);
  }

  @override
  void dispose() {
    _automation.dispose();
    _alerts.dispose();
    _alertSub?.cancel();
    super.dispose();
  }

  /// In-app banner for every NEW alert (M5). Old alerts are not shown again.
  void _onAlerts(List<AlertItem> list) {
    final fresh = list.where((a) => !a.read && !_seenAlerts.contains(a.id)).toList();
    _seenAlerts.addAll(list.map((a) => a.id));
    setState(() => _unread = list.where((a) => !a.read).length);
    if (_firstAlertBatch) {
      _firstAlertBatch = false;
      return;
    }
    if (fresh.isEmpty || !mounted) return;
    final a = fresh.first;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
        duration: const Duration(seconds: 6),
        content: Text('${a.plantName}: ${a.message}'),
        action: SnackBarAction(
          label: 'Help',
          textColor: AppColors.lime,
          onPressed: () {
            greenhouseRepository.markAlertRead(a.id);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => BedScreen(greenhouseId: a.greenhouseId)));
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      GardensScreen(user: widget.user, unread: _unread, onOpenAlerts: () => setState(() => _tab = 2)),
      ChatListScreen(uid: widget.user.uid),
      AlertsScreen(uid: widget.user.uid),
      SettingsScreen(user: widget.user),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(children: [
              const OfflineBanner(),
              Expanded(child: IndexedStack(index: _tab, children: pages)),
            ]),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22 + MediaQuery.paddingOf(context).bottom,
              child: _FloatingNav(index: _tab, unread: _unread, onTap: (i) => setState(() => _tab = i)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.unread, required this.onTap});
  final int index;
  final int unread;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.grass_rounded, 'Beds'),
    (Icons.chat_bubble_outline_rounded, 'Chat'),
    (Icons.notifications_none_rounded, 'Alerts'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [BoxShadow(color: Color(0x24211D26), blurRadius: 40, offset: Offset(0, 14))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _items.length; i++)
            Semantics(
              button: true,
              selected: i == index,
              label: _items[i].$2,
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  padding: EdgeInsets.symmetric(horizontal: i == index ? 16 : 14),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(children: [
                    Badge(
                      isLabelVisible: i == 2 && unread > 0 && i != index,
                      backgroundColor: AppColors.red,
                      smallSize: 9,
                      child: Icon(_items[i].$1, color: i == index ? AppColors.lime : AppColors.muted, size: 24),
                    ),
                    if (i == index) ...[
                      const SizedBox(width: 8),
                      Text(_items[i].$2, style: nunito(15, FontWeight.w900, color: Colors.white)),
                    ],
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
