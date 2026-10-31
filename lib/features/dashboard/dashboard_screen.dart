import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../report/report_screen.dart';
import '../shipment/process_screen.dart';
import '../shipment/set_shipment_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_tab) {
        0 => _home(),
        1 => const HistoryScreen(),
        2 => const ReportScreen(),
        _ => const ProfileScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.softBlue,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: AppColors.primary),
            label: 'Pengiriman',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment, color: AppColors.primary),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _home() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 16,
            20,
            20,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD6E6FF), AppColors.bg],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${MockData.driverName} 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const Text(
                      'Selamat bertugas hari ini!',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.notifications_none, color: AppColors.text),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  'B',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StatsCard(),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Buat Pengiriman',
                icon: Icons.add,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SetShipmentScreen()),
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengiriman Aktif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          MockData.shipmentNumber,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          formatDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${MockData.destinations.length} Titik Pengiriman',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const StepIndicator(
                      active: 1,
                      labels: [
                        'Muat Barang',
                        'Perjalanan',
                        'Bongkar',
                        'Selesai',
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Lanjutkan Pengiriman',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoadingScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengiriman Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _tab = 1),
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
              for (final r in MockData.recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShipmentTile(r),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    // Angka dummy -> ganti dari Laravel.
    return const AppCard(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _Stat(
            Icons.local_shipping_outlined,
            AppColors.primary,
            AppColors.softBlue,
            '3',
            'Pengiriman\nAktif',
          ),
          _VDivider(),
          _Stat(
            Icons.check_circle,
            AppColors.success,
            AppColors.softGreen,
            '12',
            'Selesai\nHari Ini',
          ),
          _VDivider(),
          _Stat(
            Icons.cancel_outlined,
            AppColors.danger,
            AppColors.softRed,
            '2',
            'Gagal\nHari Ini',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String value;
  final String label;

  const _Stat(this.icon, this.color, this.bg, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          IconBadge(icon, color: color, background: bg, size: 36),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 70, color: AppColors.border);
}
