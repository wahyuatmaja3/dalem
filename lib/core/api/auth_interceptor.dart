import 'package:flutter_riverpod/flutter_riverpod.dart';

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor();
});

class AuthInterceptor {
  final List<Function()> _listeners = [];

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void notifyUnauthorized() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
