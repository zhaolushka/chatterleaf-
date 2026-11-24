import 'firebase_backend.dart';
import 'mock_backend.dart';
import 'repositories.dart';

export 'models.dart';
export 'repositories.dart';

/// Demo mode by default. Run with `--dart-define=USE_FIREBASE=true` for Firebase.
const kUseFirebase = bool.fromEnvironment('USE_FIREBASE');

// One instance of each service for the whole app. Screens import this file.
final connectivity = ConnectivityService();
late final AuthRepository authRepository;
late final GreenhouseRepository greenhouseRepository;

/// Not null only in demo mode: Settings → Demo tools use it.
MockGreenhouseRepository? demoBackend;

void initServices() {
  if (kUseFirebase) {
    authRepository = FirebaseAuthRepository();
    greenhouseRepository = FirestoreGreenhouseRepository(connectivity);
  } else {
    authRepository = MockAuthRepository();
    final mock = MockGreenhouseRepository(connectivity);
    demoBackend = mock;
    greenhouseRepository = mock;
  }
}
