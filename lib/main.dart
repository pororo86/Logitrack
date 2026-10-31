import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() {
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
      home: const LoginScreen(),
    );
  }
}
