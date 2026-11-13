import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../../data/models/shipment_model.dart';

const _bulanPanjang = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Riwayat Pengiriman dari server: pencarian + filter + kelompok per bulan.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _filters = [
    'Semua',
    'Selesai',
    'Berjalan',
    'Terlambat',
    'Gagal',
  ];

  final _scroll = ScrollController();
  Timer? _debounce;
  int _ticket = 0;

  String _filter = 'Semua';
  String _query = '';

  List<ShipmentModel> _items = [];
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      _load(more: true);
    }
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loadingMore || _loading || _page >= _lastPage)) return;

    final ticket = ++_ticket; // hanya jawaban terbaru yang dipakai
    final nextPage = more ? _page + 1 : 1;

    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _loadingMore = false;
        _error = null;
      }
    });

    try {
      final result = await AppServices.I.shipments.list(
        displayStatus: _filter,
        search: _query,
        page: nextPage,
      );
      if (!mounted || ticket != _ticket) return;

      setState(() {
        _items = more ? [..._items, ...result.items] : result.items;
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
      });
    } on ApiException catch (e) {
      if (mounted && ticket == _ticket) setState(() => _error = e.message);
    } finally {
      if (mounted && ticket == _ticket) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onSearch(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  void _setFilter(String f) {
    if (_filter == f) return;
    setState(() => _filter = f);
    _load();
  }

  String _monthOf(ShipmentModel s) {
    final d = s.createdWib;
    return d == null ? '-' : '${_bulanPanjang[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          children: [
            const Text(
              'Riwayat Pengiriman',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Cari nomor pengiriman...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        f,
                        selected: _filter == f,
                        onTap: () => _setFilter(f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ..._content(),
          ],
        ),
      ),
    );
  }

  List<Widget> _content() {
    if (_loading && _items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 50),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null && _items.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _error!,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(onPressed: _load, child: const Text('Coba lagi')),
      ];
    }

    if (_items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              'Tidak ada data',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[
      Text(
        '$_total pengiriman',
        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
      ),
      const SizedBox(height: 8),
    ];

    String? lastMonth;
    for (final s in _items) {
      final month = _monthOf(s);
      if (month != lastMonth) {
        lastMonth = month;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Text(
              month,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: HistoryTile(
            RecentShipment(
              s.number,
              s.destinationCount,
              formatDate(s.createdWib ?? DateTime.now()),
              s.displayStatus,
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Halaman detail menyusul')),
            ),
          ),
        ),
      );
    }

    if (_loadingMore) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return widgets;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.softBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
