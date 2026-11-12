import 'package:flutter/material.dart';

import '../../core/auth/app_services.dart';
import '../../core/auth/session.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Session _session = AppServices.I.session;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onChanged);
    if (_session.status == SessionStatus.restoring) {
      _session.restore();
    }
  }

  /// Saat keluar atau sesi habis: tutup semua layar yang sedang terbuka.
  void _onChanged() {
    if (_session.status != SessionStatus.signedOut) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _session.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) => switch (_session.status) {
        SessionStatus.restoring => const _SplashScreen(),
        SessionStatus.signedOut => const LoginScreen(),
        SessionStatus.signedIn => const DashboardScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
