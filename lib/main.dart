import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'data/data.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

/// Tamyr — school greenhouse with talking plants.
///
/// Demo mode (default): in-memory database + simulator, no keys needed.
/// Firebase mode: `flutter run --dart-define=USE_FIREBASE=true`
/// (needs `flutterfire configure` first — see README).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kUseFirebase) await Firebase.initializeApp();
  initServices();
  runApp(const TamyrApp());
}

class TamyrApp extends StatelessWidget {
  const TamyrApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Tamyr',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
      );
}

/// Shows the login screen or the app. When the user signs in or out,
/// authStateChanges sends a new value and the screen switches by itself.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
        stream: authRepository.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Loading());
          final user = snap.data;
          if (user == null) return const LoginScreen();
          // key: a new account gets a fresh shell and never sees the previous user's data (M1).
          return HomeShell(key: ValueKey(user.uid), user: user);
        },
      );
}
