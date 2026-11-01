import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _name;
  late String _email;
  late String _phone;
  late String _company;

  @override
  void initState() {
    super.initState();
    _name = MockData.driverFullName;
    _email = MockData.driverEmail;
    _phone = MockData.driverPhone;
    _company = MockData.driverCompany;
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      setState(() {
        _name = nameController.text.trim();
        _email = emailController.text.trim();
        _phone = phoneController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  void _soon(String name) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$name menyusul')));
  }

  @override
  Widget build(BuildContext context) {
    final initials = _name
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),

          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.softBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Driver • ID ${MockData.driverId}',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      const StatusChip(
                        label: 'Akun Aktif',
                        color: AppColors.success,
                        background: AppColors.softGreen,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _editProfile,
                        child: const Text(
                          'Edit Profil',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const _SectionTitle('Informasi Pribadi'),
          const SizedBox(height: 10),

          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _InfoRow('Email', _email),
                _InfoRow('Nomor telepon', _phone),
                _InfoRow('Perusahaan', _company),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const _SectionTitle('Kendaraan'),
          const SizedBox(height: 10),

          AppCard(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kendaraan Aktif',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Belum ada kendaraan dipilih',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const _SectionTitle('Pengaturan'),
          const SizedBox(height: 10),

          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.lock_outline,
                  title: 'Akun & Keamanan',
                  subtitle: 'Password dan akses akun',
                  onTap: () => _soon('Akun & Keamanan'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _MenuTile(
                  icon: Icons.help_outline,
                  title: 'Bantuan',
                  subtitle: 'Pusat bantuan LogiTrack',
                  onTap: () => _soon('Bantuan'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar Akun'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: AppColors.text,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}
