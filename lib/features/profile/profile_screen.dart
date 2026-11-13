import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../../core/auth/app_services.dart';
import '../../core/network/api_exception.dart';

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
    final user = AppServices.I.session.user;
    _name = user?.name ?? MockData.driverFullName;
    _email = user?.email ?? MockData.driverEmail;
    _phone = user?.phone ?? MockData.driverPhone;
    _company = user?.driver?.companyName ?? MockData.driverCompany;
  }

  String _vehicleText() {
    final v = AppServices.I.session.user?.driver?.vehicle;
    if (v == null) return 'Belum ada kendaraan dipilih';
    return '${v.plateNumber} • ${v.name}';
  }

  Future<void> _editProfile() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditProfileDialog(
        name: _name,
        email: _email,
        phone: _phone,
        company: _company,
      ),
    );

    if (saved != true || !mounted) return;

    final user = AppServices.I.session.user;
    setState(() {
      _name = user?.name ?? _name;
      _phone = user?.phone ?? '';
      _company = user?.driver?.companyName ?? '';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui')));
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
                      Text(
                        'Driver • ID ${AppServices.I.session.user?.driver?.driverCode ?? MockData.driverId}',
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
                _InfoRow('Nomor telepon', _phone.isEmpty ? '-' : _phone),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kendaraan Aktif',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _vehicleText(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
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
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Keluar akun?'),
                  content: const Text(
                    'Anda harus masuk lagi untuk melanjutkan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await AppServices.I.session.logout();
              }
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

/// Dialog edit profil. Memegang controller sendiri supaya aman dibuang
/// setelah animasi tutup selesai. Email hanya dapat diubah admin.
class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
  });

  final String name;
  final String email;
  final String phone;
  final String company;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.name,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.phone,
  );
  late final TextEditingController _company = TextEditingController(
    text: widget.company,
  );

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama lengkap wajib diisi.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AppServices.I.session.updateProfile(
        name: name,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      final first = e.fieldErrors.values.expand((v) => v).firstOrNull;
      setState(() {
        _saving = false;
        _error = first ?? e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Perusahaan',
                prefixIcon: Icon(Icons.apartment),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: widget.email),
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                helperText: 'Email hanya dapat diubah oleh admin',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
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
