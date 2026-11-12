import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/shipment_model.dart';

/// Memilih satu atau beberapa perusahaan dari master Laravel.
/// Mengembalikan List<CompanyModel> lewat Navigator.pop.
class CompanyPickerScreen extends StatefulWidget {
  const CompanyPickerScreen({super.key, this.excludeIds = const {}});

  /// Perusahaan yang sudah ada di daftar tujuan (tidak dapat dipilih lagi).
  final Set<int> excludeIds;

  @override
  State<CompanyPickerScreen> createState() => _CompanyPickerScreenState();
}

class _CompanyPickerScreenState extends State<CompanyPickerScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  int _request = 0;

  List<CompanyModel> _items = [];
  final Map<int, CompanyModel> _picked = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ticket = ++_request; // hanya jawaban terbaru yang dipakai
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await AppServices.I.shipments.companies(
        search: _search.text,
      );
      if (!mounted || ticket != _request) return;
      setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted && ticket == _request) setState(() => _error = e.message);
    } finally {
      if (mounted && ticket == _request) setState(() => _loading = false);
    }
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  void _toggle(CompanyModel c) {
    setState(() {
      if (_picked.containsKey(c.id)) {
        _picked.remove(c.id);
      } else {
        _picked[c.id] = c;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Perusahaan Tujuan')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
                decoration: const InputDecoration(
                  hintText: 'Cari nama perusahaan atau alamat',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(child: _body()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: _picked.isEmpty
                    ? 'Pilih perusahaan'
                    : 'Tambahkan (${_picked.length})',
                onPressed: _picked.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_picked.values.toList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Perusahaan tidak ditemukan.\nGunakan "Titik di Peta" untuk lokasi di luar daftar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: _items.length,
      itemBuilder: (context, i) => _tile(_items[i]),
    );
  }

  Widget _tile(CompanyModel c) {
    final already = widget.excludeIds.contains(c.id);
    final checked = _picked.containsKey(c.id);
    final place = [
      c.city,
      c.address,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: already ? 0.5 : 1,
        child: InkWell(
          onTap: already ? null : () => _toggle(c),
          borderRadius: BorderRadius.circular(16),
          child: AppCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apartment,
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
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      if (place.isNotEmpty)
                        Text(
                          place,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      if (already)
                        const Text(
                          'Sudah ditambahkan',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  checked ? Icons.check_circle : Icons.circle_outlined,
                  color: checked ? AppColors.primary : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
