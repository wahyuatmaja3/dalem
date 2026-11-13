import 'package:flutter/material.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/recorder_screen.dart';
import '../features/note_detail/presentation/screens/note_detail_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String dashboard = '/dashboard';
  static const String noteDetail = '/note-detail';
  static const String recorder = '/recorder';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case noteDetail:
        final noteId = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => NoteDetailScreen(noteId: noteId),
        );
      case recorder:
        return MaterialPageRoute(builder: (_) => const RecorderScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
