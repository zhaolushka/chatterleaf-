import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'data/auth_service.dart';
import 'data/connectivity_service.dart';
import 'data/greenhouse_repository.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

/// Chatterleaf — mock Firebase by default (no keys needed for live demo).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChatterleafApp());
}

class ChatterleafApp extends StatefulWidget {
  const ChatterleafApp({super.key, this.useMock = true});

  final bool useMock;

  @override
  State<ChatterleafApp> createState() => _ChatterleafAppState();
}

class _ChatterleafAppState extends State<ChatterleafApp> {
  late final AuthService _auth;
  late final ConnectivityService _connectivity;
  late final GreenhouseRepository _repository;

  @override
  void initState() {
    super.initState();
    _auth = AuthService(useMock: widget.useMock);
    _connectivity = ConnectivityService(online: true);
    _repository = GreenhouseRepository(
      auth: _auth,
      connectivity: _connectivity,
      useMock: widget.useMock,
    );
  }

  @override
  void dispose() {
    _repository.dispose();
    _auth.dispose();
    _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: _auth),
        ChangeNotifierProvider<ConnectivityService>.value(value: _connectivity),
        ChangeNotifierProvider<GreenhouseRepository>.value(value: _repository),
      ],
      child: MaterialApp(
        title: 'Chatterleaf',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (auth.currentUser == null) return const LoginScreen();
            return const HomeShell();
          },
        ),
      ),
    );
  }
}
