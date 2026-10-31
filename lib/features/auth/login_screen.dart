import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'budi@logitrack.test');
  final _password = TextEditingController(text: 'password');
  bool _hide = true;
  bool _remember = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // simulasi API
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
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
              const SizedBox(height: 14),
              const Text(
                'LogiTrack',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Monitoring Pengiriman\nLebih Mudah dan Akurat',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'driver@perusahaan.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _hide,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hide
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? false),
                  ),
                  const Text('Ingat saya', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur lupa password menyusul'),
                      ),
                    ),
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Masuk',
                loading: _loading,
                onPressed: _login,
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'atau',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Masuk dengan Google',
                outlined: true,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Belum tersedia (hanya email + password)'),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F0FE), Color(0xFFCFE0FB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
