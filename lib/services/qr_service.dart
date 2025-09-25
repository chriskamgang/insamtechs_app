import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class QRService {
  static const String baseEnrollmentUrl = 'https://insam-lms.com/enroll';

  static String generateCourseEnrollmentUrl(String courseSlug) {
    return '$baseEnrollmentUrl/$courseSlug';
  }

  static Widget generateQRWidget({
    required String data,
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  static Future<void> shareQRCode({
    required GlobalKey qrKey,
    required String courseTitle,
    String? message,
  }) async {
    try {
      final RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/qr_code_$courseTitle.png');
      await file.writeAsBytes(pngBytes);

      final String shareText = message ?? 'Scannez ce QR code pour vous inscrire au cours: $courseTitle';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'QR Code - $courseTitle',
      );
    } catch (e) {
      throw Exception('Erreur lors du partage du QR code: $e');
    }
  }

  static Future<Uint8List> generateQRBytes({
    required String data,
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        color: foregroundColor,
        emptyColor: backgroundColor,
      );

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      qrPainter.paint(canvas, Size(size, size));
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      throw Exception('Erreur lors de la génération du QR code: $e');
    }
  }

  static Future<void> saveQRToGallery({
    required String data,
    required String filename,
    double size = 500.0,
  }) async {
    try {
      final bytes = await generateQRBytes(data: data, size: size);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename.png');
      await file.writeAsBytes(bytes);

      // Note: Pour sauvegarder dans la galerie, il faudrait utiliser
      // un package comme image_gallery_saver ou gal
      throw UnimplementedError('Sauvegarde dans la galerie non implémentée');
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  static bool isValidQRUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return false;

    return uri.host.contains('insam-lms.com') &&
           uri.path.startsWith('/enroll/');
  }

  static String? extractCourseSlugFromQR(String qrData) {
    if (!isValidQRUrl(qrData)) return null;

    final Uri uri = Uri.parse(qrData);
    final pathSegments = uri.pathSegments;

    if (pathSegments.length >= 2 && pathSegments[0] == 'enroll') {
      return pathSegments[1];
    }

    return null;
  }

  static Map<String, dynamic> generateCourseQRData({
    required String courseSlug,
    required String courseTitle,
    required String instructorName,
    String? price,
  }) {
    return {
      'type': 'course_enrollment',
      'url': generateCourseEnrollmentUrl(courseSlug),
      'slug': courseSlug,
      'title': courseTitle,
      'instructor': instructorName,
      'price': price,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}