import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/recorder_screen.dart';
import '../features/note_detail/presentation/screens/note_detail_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String noteDetail = '/note-detail';
  static const String recorder = '/recorder';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case noteDetail:
        final noteId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => NoteDetailScreen(noteId: noteId),
        );
      case recorder:
        return MaterialPageRoute(builder: (_) => const RecorderScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
