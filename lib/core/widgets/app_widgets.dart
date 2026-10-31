import 'package:flutter/material.dart';

import 'dart:io';

import '../../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Kartu putih dengan border tipis.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143478F6),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Tombol utama biru (atau outline).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                shape: shape,
                textStyle: textStyle,
                foregroundColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
              child: content,
            )
          : FilledButton(
              onPressed: loading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: shape,
                textStyle: textStyle,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : content,
            ),
    );
  }
}

/// Progress 4 langkah: Siap Kirim, Muat Barang, Perjalanan, Bongkar.
class StepIndicator extends StatelessWidget {
  final int active; // 1..4
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.active,
    this.labels = const ['Siap Kirim', 'Muat Barang', 'Perjalanan', 'Bongkar'],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final step = i + 1;
        final done = step < active;
        final isActive = step == active;
        final filled = done || isActive;
        final isFirst = i == 0;
        final isLast = i == labels.length - 1;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isFirst
                          ? Colors.transparent
                          : (step <= active
                                ? AppColors.primary
                                : AppColors.border),
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.white,
                      border: filled
                          ? null
                          : Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : Text(
                            '$step',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : AppColors.muted,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isLast
                          ? Colors.transparent
                          : (done ? AppColors.primary : AppColors.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: filled ? AppColors.text : AppColors.muted,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Chip status kecil (Selesai, Berikutnya, Menunggu).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  /// Chip otomatis dari teks status: Selesai / Berjalan / Gagal.
  factory StatusChip.of(String status) {
    switch (status) {
      case 'Gagal':
        return StatusChip(
          label: status,
          color: AppColors.danger,
          background: AppColors.softRed,
        );
      case 'Berjalan':
        return StatusChip(
          label: status,
          color: const Color(0xFFC98A12),
          background: AppColors.softYellow,
        );
      default:
        return StatusChip(
          label: status,
          color: AppColors.success,
          background: AppColors.softGreen,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Header nama perusahaan + kota tujuan.
class DestinationHeader extends StatelessWidget {
  final Destination destination;
  const DestinationHeader({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                  destination.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  destination.city,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu "Lokasi Terdeteksi" (koordinat, akurasi, waktu).
class LocationInfoCard extends StatelessWidget {
  final double lat;
  final double lng;
  final double accuracy;
  final DateTime time;
  final bool valid;

  const LocationInfoCard({
    super.key,
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.time,
    this.valid = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = valid ? AppColors.success : AppColors.danger;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.location_on, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valid ? 'Lokasi Terdeteksi' : 'Lokasi belum valid',
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.text),
                ),
                Text(
                  '${formatDateTime(time)}  •  Akurasi ±${accuracy.round()} m',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              valid ? Icons.check : Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kotak foto: placeholder, preview foto asli, tombol kamera,
/// dan info ukuran sebelum/sesudah kompres.
class PhotoBox extends StatelessWidget {
  final File? file;
  final int? beforeBytes;
  final int? afterBytes;
  final bool busy;
  final VoidCallback onCapture;
  final VoidCallback onRemove;

  const PhotoBox({
    super.key,
    required this.file,
    required this.onCapture,
    required this.onRemove,
    this.beforeBytes,
    this.afterBytes,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = file != null;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  Image.file(file!, fit: BoxFit.cover)
                else
                  GestureDetector(
                    onTap: busy ? null : onCapture,
                    child: CustomPaint(
                      painter: _DashedBoxPainter(),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              size: 34,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Ambil Foto',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (busy)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (hasPhoto && !busy)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: const CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.tonalIcon(
            onPressed: busy ? null : onCapture,
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            label: Text(
              busy
                  ? 'Memproses foto & GPS...'
                  : (hasPhoto ? 'Ambil Ulang' : 'Ambil Foto'),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.softBlue,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (hasPhoto && beforeBytes != null && afterBytes != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.compress, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Sebelum: ${formatBytes(beforeBytes!)}  →  '
                  'Sesudah: ${formatBytes(afterBytes!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Peta placeholder (digambar manual). Diganti Leaflet/Google Map nanti.
class MapPlaceholder extends StatelessWidget {
  final double height;
  final bool showRoute;

  const MapPlaceholder({super.key, this.height = 140, this.showRoute = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _MapPainter(showRoute)),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final bool showRoute;
  _MapPainter(this.showRoute);

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFE9EEF5));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * 0.55,
          s.height * 0.55,
          s.width * 0.3,
          s.height * 0.28,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFFD5EBD9),
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, s.height * 0.35),
      Offset(s.width, s.height * 0.5),
      road,
    );
    canvas.drawLine(
      Offset(s.width * 0.3, 0),
      Offset(s.width * 0.4, s.height),
      road,
    );
    canvas.drawLine(
      Offset(s.width * 0.75, 0),
      Offset(s.width * 0.7, s.height),
      road,
    );

    if (showRoute) {
      final start = Offset(s.width * 0.2, s.height * 0.8);
      final end = Offset(s.width * 0.8, s.height * 0.22);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          s.width * 0.2,
          s.height * 0.4,
          s.width * 0.55,
          s.height * 0.7,
          end.dx,
          end.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(start, 9, Paint()..color = Colors.white);
      canvas.drawCircle(start, 6, Paint()..color = AppColors.success);
      canvas.drawCircle(end, 10, Paint()..color = AppColors.danger);
      canvas.drawCircle(end, 4, Paint()..color = Colors.white);
    } else {
      final c = Offset(s.width / 2, s.height / 2);
      canvas.drawCircle(
        c,
        28,
        Paint()..color = AppColors.primary.withValues(alpha: 0.18),
      );
      canvas.drawCircle(c, 11, Paint()..color = Colors.white);
      canvas.drawCircle(c, 8, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.showRoute != showRoute;
}

class _DashedBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = AppColors.softBlue.withValues(alpha: 0.55),
    );
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Kotak ikon lembut (dipakai di kartu & daftar).
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const IconBadge(
    this.icon, {
    super.key,
    this.color = AppColors.primary,
    this.background = AppColors.softBlue,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Baris pengiriman (Dashboard & Riwayat).
class ShipmentTile extends StatelessWidget {
  final RecentShipment item;
  final bool detailed; // true = tampilkan perusahaan, tanggal & panah
  final VoidCallback? onTap;

  const ShipmentTile(this.item, {super.key, this.detailed = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Row(
          children: [
            const IconBadge(Icons.local_shipping_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (detailed && item.company != null)
                    Text(
                      item.company!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  Text(
                    detailed
                        ? '${item.date} • ${item.points} Tujuan'
                        : '${item.points} Tujuan',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip.of(item.status),
            if (detailed)
              const Icon(Icons.chevron_right, color: AppColors.text),
          ],
        ),
      ),
    );
  }
}
