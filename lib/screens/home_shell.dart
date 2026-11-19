import 'package:material_ui/material_ui.dart';

import '../widgets/offline_banner.dart';
import 'alerts_screen.dart';
import 'chat_screen.dart';
import 'control_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  static const _titles = ['Home', 'Control', 'History', 'Chat', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onOpenAlerts: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AlertsScreen()),
          );
        },
      ),
      const ControlScreen(),
      const HistoryScreen(),
      const ChatScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Alerts',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Control'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
