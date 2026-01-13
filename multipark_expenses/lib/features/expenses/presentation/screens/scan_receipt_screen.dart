import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/expenses_bloc.dart';
import 'expense_form_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Erro ao inicializar câmara: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpensesBloc, ExpensesState>(
      listener: (context, state) {
        if (state is ReceiptScanned) {
          // Navegar para formulário com dados extraídos
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseFormScreen(ocrResult: state.result),
            ),
          );
        } else if (state is ReceiptScanError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera Preview
            if (_isInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Overlay
            Positioned.fill(
              child: _buildOverlay(),
            ),

            // Top Bar
            _buildTopBar(),

            // Bottom Controls
            _buildBottomControls(),

            // Loading
            BlocBuilder<ExpensesBloc, ExpensesState>(
              builder: (context, state) {
                if (state is ReceiptScanning) {
                  return Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'A processar fatura...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return CustomPaint(
      painter: _ScanOverlayPainter(),
      child: Container(),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botão Fechar
            _buildCircleButton(
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
            ),
            // Título
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Scan de Fatura',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Botão Flash
            _buildCircleButton(
              icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
              onPressed: _toggleFlash,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dicas
            const Text(
              'Posicione a fatura dentro da moldura',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Controlos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Galeria
                _buildControlButton(
                  icon: Icons.photo_library,
                  label: 'Galeria',
                  onPressed: _pickFromGallery,
                ),
                // Capturar
                _buildCaptureButton(),
                // Entrada Manual
                _buildControlButton(
                  icon: Icons.edit,
                  label: 'Manual',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpenseFormScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureImage,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      debugPrint('Erro ao alternar flash: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      _processImage(File(image.path));
    } catch (e) {
      debugPrint('Erro ao capturar imagem: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _processImage(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
    }
  }

  void _processImage(File image) {
    context.read<ExpensesBloc>().add(ReceiptScanRequested(image));
  }
}

/// Painter para o overlay do scanner
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Área do documento (A4 ratio aproximado)
    final docWidth = size.width * 0.85;
    final docHeight = docWidth * 1.4;
    final left = (size.width - docWidth) / 2;
    final top = (size.height - docHeight) / 2 - 50;

    final docRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, docWidth, docHeight),
      const Radius.circular(12),
    );

    // Caminho com buraco
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(docRect);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Borda da área de scan
    final borderPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(docRect, borderPaint);

    // Cantos destacados
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top + 12),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + cornerLength, top),
      Offset(left + 12, top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(left + docWidth, top + cornerLength),
      Offset(left + docWidth, top + 12),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + docWidth - cornerLength, top),
      Offset(left + docWidth - 12, top),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(left, top + docHeight - cornerLength),
      Offset(left, top + docHeight - 12),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + cornerLength, top + docHeight),
      Offset(left + 12, top + docHeight),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(left + docWidth, top + docHeight - cornerLength),
      Offset(left + docWidth, top + docHeight - 12),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + docWidth - cornerLength, top + docHeight),
      Offset(left + docWidth - 12, top + docHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
