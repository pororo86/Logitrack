import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Layar kamera penuh. Mengembalikan path foto (String) lewat Navigator.pop,
/// atau null jika pengguna menutup tanpa memotret.
class CameraScreen extends StatefulWidget {
  final String title;
  const CameraScreen({super.key, this.title = 'Ambil Foto'});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _initializing = false;
  bool _taking = false;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // Lepas kamera saat aplikasi di background, nyalakan lagi saat kembali.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c != null && c.value.isInitialized) {
        _controller = null;
        if (mounted) setState(() {});
        c.dispose();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null && !_initializing) _init();
    }
  }

  Future<void> _init() async {
    _initializing = true;
    if (mounted) setState(() => _error = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _error = 'Perangkat tidak memiliki kamera.');
        }
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _flash = FlashMode.off;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            (e.code == 'CameraAccessDenied' ||
                e.code == 'CameraAccessDeniedWithoutPrompt' ||
                e.code == 'CameraAccessRestricted')
            ? 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan aplikasi.'
            : 'Kamera tidak dapat dibuka (${e.code}).';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Kamera tidak dapat dibuka: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null) return;
    final next = _flash == FlashMode.off ? FlashMode.auto : FlashMode.off;
    try {
      await c.setFlashMode(next);
      setState(() => _flash = next);
    } catch (_) {
      // Perangkat tanpa flash: abaikan.
    }
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _taking) return;
    setState(() => _taking = true);
    try {
      final file = await c.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _taking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto (${e.code})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _error != null
                  ? _errorView()
                  : (c == null || !c.value.isInitialized)
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Center(child: CameraPreview(c)),
            ),
            // Bar atas
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: c == null ? null : _toggleFlash,
                    icon: Icon(
                      _flash == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_auto,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Tombol shutter
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _shoot,
                  child: Container(
                    width: 74,
                    height: 74,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _taking ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _init,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
