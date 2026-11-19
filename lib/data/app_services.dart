import 'auth_service.dart';
import 'connectivity_service.dart';
import 'greenhouse_repository.dart';

/// Convenience factory used by tests. Production wiring lives in `main.dart`.
class AppServices {
  AppServices({this.useMock = true}) {
    auth = AuthService(useMock: useMock);
    connectivity = ConnectivityService(online: true);
    repository = GreenhouseRepository(
      auth: auth,
      connectivity: connectivity,
      useMock: useMock,
    );
  }

  final bool useMock;
  late final AuthService auth;
  late final ConnectivityService connectivity;
  late final GreenhouseRepository repository;

  void dispose() {
    repository.dispose();
    auth.dispose();
    connectivity.dispose();
  }
}
