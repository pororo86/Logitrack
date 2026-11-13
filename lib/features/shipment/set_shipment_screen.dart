import 'package:flutter/material.dart';

import '../../core/auth/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../../data/models/shipment_model.dart';
import '../../data/repositories/shipment_repository.dart';
import '../validation/validation_screen.dart';
import 'add_destination_screen.dart';
import 'company_picker_screen.dart';

enum _Mode { list, manual }

class SetShipmentScreen extends StatefulWidget {
  const SetShipmentScreen({super.key});

  @override
  State<SetShipmentScreen> createState() => _SetShipmentScreenState();
}

class _SetShipmentScreenState extends State<SetShipmentScreen> {
  late final TextEditingController _company = TextEditingController(
    text: AppServices.I.session.user?.driver?.companyName ?? '',
  );

  _Mode _mode = _Mode.list;

  // Mode "Dari Daftar": pengiriman buatan admin
  List<ShipmentModel> _available = [];
  bool _hasActive = false;
  bool _loadingList = true;
  String? _listError;
  ShipmentModel? _picked;

  // Mode "Buat Manual"
  final List<Destination> _items = [];

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailable(autoSwitch: true);
  }

  @override
  void dispose() {
    _company.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- data

  Future<void> _loadAvailable({bool autoSwitch = false}) async {
    setState(() {
      _loadingList = true;
      _listError = null;
    });

    try {
      final result = await AppServices.I.shipments.available();
      if (!mounted) return;

      setState(() {
        _available = result.items;
        _hasActive = result.hasActive;
        if (_picked != null && !result.items.any((s) => s.id == _picked!.id)) {
          _picked = null;
        }
        // Daftar kosong: langsung ke opsi di luar daftar.
        if (autoSwitch && result.items.isEmpty) _mode = _Mode.manual;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _listError = e.message);
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _addFromCompanies() async {
    final picked = await Navigator.of(context).push<List<CompanyModel>>(
      MaterialPageRoute(
        builder: (_) => CompanyPickerScreen(
          excludeIds: _items.map((d) => d.companyId).whereType<int>().toSet(),
        ),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;

    setState(() {
      for (final c in picked) {
        _items.add(
          Destination(
            name: c.name,
            city: c.city ?? '-',
            address: c.address ?? c.city ?? '-',
            lat: c.lat,
            lng: c.lng,
            radius: c.radius,
            companyId: c.id,
          ),
        );
      }
      _error = null;
    });
  }

  Future<void> _addFromMap() async {
    final d = await Navigator.of(context).push<Destination>(
      MaterialPageRoute(builder: (_) => const AddDestinationScreen()),
    );
    if (d == null || !mounted) return;

    setState(() {
      _items.add(d);
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_hasActive) return;

    if (_mode == _Mode.list && _picked == null) {
      setState(() => _error = 'Pilih salah satu pengiriman dari daftar.');
      return;
    }
    if (_mode == _Mode.manual && _items.isEmpty) {
      setState(() => _error = 'Minimal 1 tujuan pengiriman.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final vehicleId = MockData.selectedVehicle?.serverId;
      final repo = AppServices.I.shipments;

      final ShipmentModel shipment;
      if (_mode == _Mode.list) {
        shipment = await repo.claim(
          number: _picked!.number,
          vehicleId: vehicleId,
        );
      } else {
        shipment = await repo.create(
          vehicleId: vehicleId,
          companyName: _company.text.trim(),
          destinations: _items
              .map(
                (d) => d.companyId != null
                    ? ShipmentRepository.companyDestination(d.companyId!)
                    : ShipmentRepository.manualDestination(
                        name: d.name,
                        address: d.address,
                        city: d.city,
                        lat: d.lat,
                        lng: d.lng,
                        radius: d.radius,
                      ),
              )
              .toList(),
        );
      }

      _enter(shipment);
    } on ApiException catch (e) {
      if (!mounted) return;
      final firstField = e.fieldErrors.values.expand((v) => v).firstOrNull;
      setState(() => _error = firstField ?? e.message);

      // Sudah diambil driver lain: perbarui daftar.
      if (_mode == _Mode.list && e.statusCode == 409) _loadAvailable();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Pengiriman dari server menjadi dasar alur layar berikutnya.
  void _enter(ShipmentModel s) {
    FlowState.reset();
    FlowState.sync(s);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ValidationScreen(kind: ValidationKind.ready),
      ),
    );
  }
  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final listMode = _mode == _Mode.list;
    final canSubmit =
        !_hasActive && (listMode ? _picked != null : _items.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Set Pengiriman')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<_Mode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _Mode.list,
                      icon: Icon(Icons.list_alt),
                      label: Text('Dari Daftar'),
                    ),
                    ButtonSegment(
                      value: _Mode.manual,
                      icon: Icon(Icons.edit_note),
                      label: Text('Buat Manual'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() {
                    _mode = s.first;
                    _error = null;
                  }),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_hasActive) ...[
                    _noticeBox(
                      'Anda masih memiliki pengiriman aktif. Selesaikan terlebih '
                      'dahulu sebelum mengambil atau membuat pengiriman baru.',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_error != null) ...[
                    _errorBox(_error!),
                    const SizedBox(height: 12),
                  ],
                  ...(listMode ? _listSection() : _manualSection()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: listMode ? 'Ambil Pengiriman' : 'Simpan dan Lanjut',
                loading: _saving,
                onPressed: canSubmit ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- mode: dari daftar admin

  List<Widget> _listSection() {
    return [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Pengiriman dari Admin',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loadingList ? null : () => _loadAvailable(),
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
      const Text(
        'Pilih pengiriman yang sudah dibuat admin. Tujuan dan radius validasi mengikuti data admin.',
        style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
      ),
      const SizedBox(height: 12),
      if (_loadingList && _available.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_listError != null) ...[
        _errorBox(_listError!),
        TextButton(onPressed: _loadAvailable, child: const Text('Coba lagi')),
      ] else if (_available.isEmpty)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Belum ada pengiriman dari admin.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Anda tetap bisa membuat pengiriman sendiri di luar daftar.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => setState(() => _mode = _Mode.manual),
                child: const Text('Buat Manual'),
              ),
            ],
          ),
        )
      else ...[
        for (final s in _available) _shipmentCard(s),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _mode = _Mode.manual),
            child: const Text('Tidak ada di daftar? Buat manual'),
          ),
        ),
      ],
    ];
  }

  Widget _shipmentCard(ShipmentModel s) {
    final selected = _picked?.id == s.id;
    final eta = s.etaWib;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() {
          _picked = selected ? null : s;
          _error = null;
        }),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${s.destinations.length} tujuan'
                '${s.cargoType != null && s.cargoType!.isNotEmpty ? ' • ${s.cargoType}' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              if (eta != null)
                Text(
                  'Estimasi tiba ${formatDateTime(eta)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              if (selected) ...[
                const Divider(height: 20),
                for (final d in s.destinations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.softBlue,
                          child: Text(
                            '${d.sequence}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              if (d.city != null)
                                Text(
                                  d.city!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---- mode: buat manual (di luar daftar)

  List<Widget> _manualSection() {
    return [
      const Text(
        'Nama Perusahaan',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _company,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Nama perusahaan pengirim'),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Daftar Tujuan Pengiriman',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${_items.length} tujuan',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_items.isEmpty)
        const AppCard(
          child: Text(
            'Belum ada tujuan. Tambahkan dari daftar perusahaan, atau tandai titik di peta.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _items.length,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
        },
        itemBuilder: (context, i) {
          final d = _items[i];
          return Padding(
            key: ObjectKey(d),
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.bg,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${d.city} • ${d.companyId != null ? 'Dari daftar' : 'Titik peta'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.drag_indicator,
                        color: AppColors.muted,
                        size: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _items.removeAt(i)),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addFromCompanies,
              icon: const Icon(Icons.apartment, size: 18),
              label: const Text('Dari Daftar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addFromMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Titik di Peta'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Perusahaan tidak ada di daftar? Tandai titiknya langsung di peta.',
        style: TextStyle(fontSize: 11.5, color: AppColors.muted),
      ),
    ];
  }

  // ---- kotak pesan

  Widget _errorBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF8A5A00),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
