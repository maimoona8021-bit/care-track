import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:sehatfile/core/theme/app_colors.dart';
import 'package:sehatfile/core/theme/app_text_styles.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
  });

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState
    extends State<QrScannerScreen> {
  // =====================================================
  // SCANNER CONTROLLER
  // =====================================================

  final MobileScannerController _scannerController =
  MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
    ],
  );

  // =====================================================
  // STATUS
  // =====================================================

  bool _processingQr = false;

  String _statusMessage =
      'Position the Health QR inside the frame';

  // =====================================================
  // OLD CARE TRACK QR PREFIX
  // =====================================================

  static const String _oldCareTrackPrefix =
      'caretrack://health-share/';

  // =====================================================
  // NEW CARE TRACK WEB VIEWER
  //
  // This is the HTTPS URL that normal QR scanners
  // such as Google Lens, Camera, CamScanner, etc.
  // will be able to open in a browser.
  // =====================================================

  static const String _careTrackViewerHost =
      'xkuijvlgqfguzpvbnrfe.supabase.co';

  static const String _careTrackViewerPath =
      '/functions/v1/view-health-share';

  // =====================================================
  // EXTRACT SHARE ID
  //
  // Supports BOTH:
  //
  // OLD:
  // caretrack://health-share/ABC123
  //
  // NEW:
  // https://.../view-health-share?shareId=ABC123
  // =====================================================

  String? _extractShareId(
      String rawValue,
      ) {
    final String value =
    rawValue.trim();

    if (value.isEmpty) {
      return null;
    }

    // ===============================================
    // OLD CARE TRACK FORMAT
    // ===============================================

    if (value.startsWith(
      _oldCareTrackPrefix,
    )) {
      final String shareId =
      value
          .substring(
        _oldCareTrackPrefix.length,
      )
          .trim();

      if (shareId.isEmpty) {
        return null;
      }

      return shareId;
    }

    // ===============================================
    // NEW HTTPS FORMAT
    // ===============================================

    final Uri? uri =
    Uri.tryParse(
      value,
    );

    if (uri == null) {
      return null;
    }

    if (uri.scheme != 'https') {
      return null;
    }

    if (uri.host !=
        _careTrackViewerHost) {
      return null;
    }

    if (uri.path !=
        _careTrackViewerPath) {
      return null;
    }

    final String shareId =
        uri.queryParameters[
        'shareId']
            ?.trim() ??
            '';

    if (shareId.isEmpty) {
      return null;
    }

    return shareId;
  }

  // =====================================================
  // HANDLE QR
  // =====================================================

  Future<void> _handleQr(
      BarcodeCapture capture,
      ) async {
    if (_processingQr) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    String? rawValue;

    for (final Barcode barcode
    in capture.barcodes) {
      final String value =
          barcode.rawValue
              ?.trim() ??
              '';

      if (value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }

    if (rawValue == null ||
        rawValue.isEmpty) {
      return;
    }

    // ===================================================
    // EXTRACT SHARE ID
    // ===================================================

    final String? shareId =
    _extractShareId(
      rawValue,
    );

    // ===================================================
    // INVALID QR
    // ===================================================

    if (shareId == null ||
        shareId.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage =
        'This is not a valid Care Track Health QR.';
      });

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid QR. Please scan a Care Track Health QR.',
          ),
        ),
      );

      return;
    }

    // ===================================================
    // VALID QR
    // ===================================================

    if (!mounted) {
      return;
    }

    setState(() {
      _processingQr = true;

      _statusMessage =
      'Health QR detected...';
    });

    try {
      await _scannerController
          .stop();

      if (!mounted) {
        return;
      }

      // Return only shareId to QrCodeScreen.
      Navigator.pop(
        context,
        shareId,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _processingQr = false;

        _statusMessage =
        'Position the Health QR inside the frame';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to process QR: $e',
          ),
        ),
      );

      try {
        await _scannerController
            .start();
      } catch (_) {}
    }
  }

  // =====================================================
  // TORCH
  // =====================================================

  Future<void> _toggleTorch() async {
    try {
      await _scannerController
          .toggleTorch();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Flashlight is not available on this device.',
          ),
        ),
      );
    }
  }

  // =====================================================
  // SWITCH CAMERA
  // =====================================================

  Future<void> _switchCamera() async {
    try {
      await _scannerController
          .switchCamera();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to switch camera.',
          ),
        ),
      );
    }
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _scannerController.dispose();

    super.dispose();
  }

  // =====================================================
  // SCREEN
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      Colors.black,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor:
        Colors.black,

        foregroundColor:
        Colors.white,

        elevation: 0,

        title: const Text(
          'Scan Health QR',
        ),

        actions: [
          IconButton(
            tooltip:
            'Flashlight',

            onPressed:
            _processingQr
                ? null
                : _toggleTorch,

            icon:
            const Icon(
              Icons
                  .flashlight_on_outlined,
            ),
          ),

          IconButton(
            tooltip:
            'Switch Camera',

            onPressed:
            _processingQr
                ? null
                : _switchCamera,

            icon:
            const Icon(
              Icons
                  .cameraswitch_outlined,
            ),
          ),
        ],
      ),

      // =================================================
      // CAMERA
      // =================================================

      body: SafeArea(
        child: Stack(
          fit:
          StackFit.expand,

          children: [
            // ===========================================
            // CAMERA SCANNER
            // ===========================================

            MobileScanner(
              controller:
              _scannerController,

              onDetect:
              _handleQr,

              errorBuilder: (
                  context,
                  error,
                  ) {
                return Container(
                  color:
                  Colors.black,

                  alignment:
                  Alignment.center,

                  padding:
                  const EdgeInsets.all(
                    30,
                  ),

                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [
                      const Icon(
                        Icons
                            .no_photography_outlined,

                        size:
                        65,

                        color:
                        Colors.white70,
                      ),

                      const SizedBox(
                        height:
                        18,
                      ),

                      const Text(
                        'Camera unavailable',

                        textAlign:
                        TextAlign.center,

                        style:
                        TextStyle(
                          color:
                          Colors.white,

                          fontSize:
                          18,

                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height:
                        8,
                      ),

                      Text(
                        'Please allow camera access to scan Health QR codes.',

                        textAlign:
                        TextAlign.center,

                        style:
                        AppTextStyles
                            .bodySmall
                            .copyWith(
                          color:
                          Colors.white70,

                          height:
                          1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ===========================================
            // DARK OVERLAY
            // ===========================================

            Container(
              color:
              Colors.black
                  .withValues(
                alpha:
                0.18,
              ),
            ),

            // ===========================================
            // CONTENT
            // ===========================================

            Padding(
              padding:
              const EdgeInsets.all(
                20,
              ),

              child: Column(
                children: [
                  const Spacer(),

                  // =====================================
                  // SCAN FRAME
                  // =====================================

                  SizedBox(
                    width:
                    270,

                    height:
                    270,

                    child: Stack(
                      children: [
                        Container(
                          width:
                          double.infinity,

                          height:
                          double.infinity,

                          decoration:
                          BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(
                              26,
                            ),

                            border:
                            Border.all(
                              color:
                              Colors.white
                                  .withValues(
                                alpha:
                                0.35,
                              ),

                              width:
                              1,
                            ),
                          ),
                        ),

                        Positioned(
                          top:
                          0,

                          left:
                          0,

                          child:
                          _corner(
                            top:
                            true,

                            left:
                            true,
                          ),
                        ),

                        Positioned(
                          top:
                          0,

                          right:
                          0,

                          child:
                          _corner(
                            top:
                            true,

                            left:
                            false,
                          ),
                        ),

                        Positioned(
                          bottom:
                          0,

                          left:
                          0,

                          child:
                          _corner(
                            top:
                            false,

                            left:
                            true,
                          ),
                        ),

                        Positioned(
                          bottom:
                          0,

                          right:
                          0,

                          child:
                          _corner(
                            top:
                            false,

                            left:
                            false,
                          ),
                        ),

                        if (_processingQr)
                          Container(
                            width:
                            double.infinity,

                            height:
                            double.infinity,

                            decoration:
                            BoxDecoration(
                              color:
                              Colors.black
                                  .withValues(
                                alpha:
                                0.40,
                              ),

                              borderRadius:
                              BorderRadius.circular(
                                26,
                              ),
                            ),

                            alignment:
                            Alignment.center,

                            child:
                            const CircularProgressIndicator(
                              color:
                              Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height:
                    28,
                  ),

                  // =====================================
                  // STATUS
                  // =====================================

                  Text(
                    _statusMessage,

                    textAlign:
                    TextAlign.center,

                    style:
                    const TextStyle(
                      color:
                      Colors.white,

                      fontSize:
                      17,

                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height:
                    8,
                  ),

                  Text(
                    'Care Track automatically detects valid Health QR codes.',

                    textAlign:
                    TextAlign.center,

                    style:
                    AppTextStyles
                        .bodySmall
                        .copyWith(
                      color:
                      Colors.white70,

                      height:
                      1.4,
                    ),
                  ),

                  const Spacer(),

                  // =====================================
                  // SECURITY
                  // =====================================

                  Container(
                    padding:
                    const EdgeInsets.all(
                      14,
                    ),

                    decoration:
                    BoxDecoration(
                      color:
                      Colors.black
                          .withValues(
                        alpha:
                        0.45,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        15,
                      ),

                      border:
                      Border.all(
                        color:
                        Colors.white
                            .withValues(
                          alpha:
                          0.12,
                        ),
                      ),
                    ),

                    child:
                    Row(
                      children: [
                        Container(
                          width:
                          40,

                          height:
                          40,

                          decoration:
                          BoxDecoration(
                            color:
                            Colors.teal.shade50,

                            borderRadius:
                            BorderRadius.circular(
                              11,
                            ),
                          ),

                          child:
                          Icon(
                            Icons.security_rounded,

                            color:
                            AppColors.primary,
                          ),
                        ),

                        const SizedBox(
                          width:
                          11,
                        ),

                        const Expanded(
                          child:
                          Text(
                            'Only valid Care Track Health QR codes will be accepted.',

                            style:
                            TextStyle(
                              color:
                              Colors.white70,

                              height:
                              1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SCANNER CORNER
  // =====================================================

  Widget _corner({
    required bool top,
    required bool left,
  }) {
    return SizedBox(
      width:
      45,

      height:
      45,

      child:
      CustomPaint(
        painter:
        _ScannerCornerPainter(
          top:
          top,

          left:
          left,

          color:
          AppColors.primary,
        ),
      ),
    );
  }
}

// =======================================================
// SCANNER CORNER PAINTER
// =======================================================

class _ScannerCornerPainter
    extends CustomPainter {
  final bool top;
  final bool left;
  final Color color;

  const _ScannerCornerPainter({
    required this.top,
    required this.left,
    required this.color,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final Paint paint =
    Paint()
      ..color =
          color
      ..strokeWidth =
      5
      ..style =
          PaintingStyle.stroke
      ..strokeCap =
          StrokeCap.round;

    final Path path =
    Path();

    if (top &&
        left) {
      path.moveTo(
        0,
        size.height,
      );

      path.lineTo(
        0,
        0,
      );

      path.lineTo(
        size.width,
        0,
      );
    } else if (top &&
        !left) {
      path.moveTo(
        0,
        0,
      );

      path.lineTo(
        size.width,
        0,
      );

      path.lineTo(
        size.width,
        size.height,
      );
    } else if (!top &&
        left) {
      path.moveTo(
        0,
        0,
      );

      path.lineTo(
        0,
        size.height,
      );

      path.lineTo(
        size.width,
        size.height,
      );
    } else {
      path.moveTo(
        0,
        size.height,
      );

      path.lineTo(
        size.width,
        size.height,
      );

      path.lineTo(
        size.width,
        0,
      );
    }

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _ScannerCornerPainter
      oldDelegate,
      ) {
    return oldDelegate.color !=
        color ||
        oldDelegate.top !=
            top ||
        oldDelegate.left !=
            left;
  }
}