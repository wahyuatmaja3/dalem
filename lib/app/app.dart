import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class DalemApp extends StatelessWidget {
  final String initialRoute;

  const DalemApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dalem',
      theme: AppTheme.light,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
