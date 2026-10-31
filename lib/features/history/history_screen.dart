import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';

/// Riwayat Pengiriman: pencarian + filter Semua / Selesai / Gagal.
/// Data dari MockData.history -> ganti dengan endpoint Laravel nanti.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filter; // null = Semua
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final items = MockData.history.where((s) {
      final okStatus = _filter == null || s.status == _filter;
      final okQuery =
          s.number.toLowerCase().contains(q) ||
          (s.company ?? '').toLowerCase().contains(q);
      return okStatus && okQuery;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              'Riwayat Pengiriman',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari nomor pengiriman atau perusahaan',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FilterChip(
                      'Semua',
                      _filter == null,
                      AppColors.primary,
                      () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      'Selesai',
                      _filter == 'Selesai',
                      AppColors.success,
                      () => setState(() => _filter = 'Selesai'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      'Gagal',
                      _filter == 'Gagal',
                      AppColors.danger,
                      () => setState(() => _filter = 'Gagal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada data',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        ShipmentTile(items[i], detailed: true),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip(this.label, this.selected, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
