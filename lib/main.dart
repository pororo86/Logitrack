import 'package:flutter/material.dart';

import 'core/auth/app_services.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppServices.use(AppServices.create());
  runApp(const LogiTrackApp());
}

class LogiTrackApp extends StatelessWidget {
  const LogiTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogiTrack',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}
