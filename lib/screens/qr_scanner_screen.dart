import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/qr_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = false;
  String? _scannedData;

  // Simulation du scan QR pour le moment
  void _simulateQRScan() {
    setState(() {
      _isScanning = true;
    });

    // Simuler un délai de scan
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scannedData = QRService.generateCourseEnrollmentUrl('flutter-development-101');
        });
        _processScannedData(_scannedData!);
      }
    });
  }

  void _processScannedData(String data) {
    if (QRService.isValidQRUrl(data)) {
      final courseSlug = QRService.extractCourseSlugFromQR(data);
      if (courseSlug != null) {
        _showEnrollmentDialog(courseSlug, data);
      } else {
        _showErrorDialog('URL QR invalide');
      }
    } else {
      _showErrorDialog('Ce QR code ne correspond pas à un cours INSAM LMS');
    }
  }

  void _showEnrollmentDialog(String courseSlug, String url) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: const Color(0xFF1E3A8A),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cours trouvé !',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voulez-vous consulter ce cours ?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slug du cours:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseSlug,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Naviguer vers les détails du cours
                Navigator.pushNamed(
                  context,
                  '/course-detail',
                  arguments: {
                    'slug': courseSlug,
                    'courseTitle': 'Cours depuis QR',
                    'instructor': 'Instructeur',
                    'rating': 5.0,
                    'price': '0',
                    'description': 'Cours scanné via QR code',
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Consulter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Erreur',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.close,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.scanQR,
          style: TextStyle(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Scanner Area (simulation)
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E3A8A),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Scanner Overlay
                  Center(
                    child: Container(
                      width: screenWidth * 0.6,
                      height: screenWidth * 0.6,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Corner indicators
                          ...List.generate(4, (index) {
                            final isTop = index < 2;
                            final isLeft = index % 2 == 0;
                            return Positioned(
                              top: isTop ? -2 : null,
                              bottom: isTop ? null : -2,
                              left: isLeft ? -2 : null,
                              right: isLeft ? null : -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.only(
                                    topLeft: isTop && isLeft
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    topRight: isTop && !isLeft
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    bottomLeft: !isTop && isLeft
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    bottomRight: !isTop && !isLeft
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Loading indicator when scanning
                          if (_isScanning)
                            const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Instructions
                  Positioned(
                    bottom: screenHeight * 0.15,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          _isScanning
                              ? 'Scan en cours...'
                              : 'Placez le QR code dans le cadre',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Text(
                          'Le scan se fera automatiquement',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: screenWidth * 0.035,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              children: [
                // Simulate Scan Button (pour les tests)
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.06,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _simulateQRScan,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: Text(
                      _isScanning ? 'Scan en cours...' : 'Simuler un scan',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenWidth * 0.03),

                // Info text
                Text(
                  'Note: Cette version utilise une simulation du scan QR.\nLa vraie fonctionnalité nécessite qr_code_scanner.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: screenWidth * 0.03,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}