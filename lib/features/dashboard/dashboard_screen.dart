import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../shipment/process_screen.dart';
import '../shipment/set_shipment_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  static const _tabNames = ['Beranda', 'Pengiriman', 'Notifikasi', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tab == 0
          ? _home()
          : SafeArea(
              child: Center(
                child: Text(
                  'Halaman ${_tabNames[_tab]}\nakan dibuat di tahap berikutnya',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            ),
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
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
            label: 'Pengiriman',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label: 'Notifikasi',
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
                      'Halo, ${MockData.driverName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const Text(
                      'Selamat bertugas hari ini',
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add,
                      label: 'Buat Pengiriman',
                      filled: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SetShipmentScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.history,
                      label: 'Riwayat Pengiriman',
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                ],
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
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.number,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${r.points} Titik Pengiriman',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                r.date,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(
                          label: r.status,
                          color: AppColors.success,
                          background: AppColors.softGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.primary : Colors.white,
                border: filled
                    ? null
                    : Border.all(color: AppColors.text, width: 1.5),
              ),
              child: Icon(
                icon,
                color: filled ? Colors.white : AppColors.text,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
