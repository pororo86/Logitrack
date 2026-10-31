import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/mock_data.dart';
import '../validation/validation_screen.dart';
import 'add_destination_screen.dart';

class SetShipmentScreen extends StatefulWidget {
  const SetShipmentScreen({super.key});

  @override
  State<SetShipmentScreen> createState() => _SetShipmentScreenState();
}

class _SetShipmentScreenState extends State<SetShipmentScreen> {
  final TextEditingController _company = TextEditingController(
    text: 'PT Sumber Makmur',
  );
  final List<Destination> _items = <Destination>[];

  @override
  void initState() {
    super.initState();
    _items.addAll(MockData.destinations);
  }

  @override
  void dispose() {
    _company.dispose();
    super.dispose();
  }

  Future<void> _addDestination() async {
    final Destination? d = await Navigator.of(context).push<Destination>(
      MaterialPageRoute<Destination>(
        builder: (_) => const AddDestinationScreen(),
      ),
    );
    if (d == null || !mounted) return;
    setState(() => _items.add(d));
  }

  void _save() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 1 tujuan pengiriman')),
      );
      return;
    }
    MockData.destinations = List<Destination>.of(_items);
    FlowState.reset();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ValidationScreen(kind: ValidationKind.ready),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Pengiriman')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Nama Perusahaan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: _company),
                  const SizedBox(height: 18),
                  const Text(
                    'Jumlah Kiriman',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _items.length > 1
                              ? () => setState(() => _items.removeLast())
                              : null,
                          icon: const Icon(
                            Icons.remove,
                            color: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${_items.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addDestination,
                          icon: const Icon(Icons.add, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Daftar Tujuan Pengiriman',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                                      '${d.city} • ${d.lat.toStringAsFixed(4)}, '
                                      '${d.lng.toStringAsFixed(4)}',
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
                                onPressed: () =>
                                    setState(() => _items.removeAt(i)),
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
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _addDestination,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppColors.primary, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Tambah Tujuan',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: 'Simpan dan Lanjut',
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
