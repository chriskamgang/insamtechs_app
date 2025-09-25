import 'package:flutter/services.dart';
import '../models/order.dart';

class ReceiptService {
  static const String _appName = 'INSAM TCHS';
  static const String _appAddress = 'Yaoundé, Cameroun';
  static const String _appPhone = '+237 xxx xxx xxx';
  static const String _appEmail = 'contact@insamtchs.com';

  /// Generate receipt text for an order
  String generateReceiptText(Order order) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('=' * 50);
    buffer.writeln(_appName.toUpperCase());
    buffer.writeln(_appAddress);
    buffer.writeln(_appPhone);
    buffer.writeln(_appEmail);
    buffer.writeln('=' * 50);
    buffer.writeln();

    // Receipt title
    buffer.writeln('REÇU DE PAIEMENT');
    buffer.writeln();

    // Order information
    buffer.writeln('INFORMATIONS DE LA COMMANDE');
    buffer.writeln('-' * 30);
    buffer.writeln('Numéro: #${order.orderNumber}');
    buffer.writeln('Date: ${_formatDate(order.createdAt)}');
    buffer.writeln('Statut: ${order.statusText}');
    if (order.paidAt != null) {
      buffer.writeln('Payé le: ${_formatDate(order.paidAt!)}');
    }
    buffer.writeln();

    // Formation details
    if (order.formation != null) {
      buffer.writeln('FORMATION');
      buffer.writeln('-' * 30);
      buffer.writeln('Nom: ${order.formation!.title}');
      if (order.formation!.description.isNotEmpty) {
        buffer.writeln('Description: ${order.formation!.description}');
      }
      buffer.writeln();
    }

    // Payment details
    buffer.writeln('PAIEMENT');
    buffer.writeln('-' * 30);
    if (order.paymentMethod != null) {
      buffer.writeln('Méthode: ${order.paymentMethodText}');
    }
    if (order.paymentReference != null) {
      buffer.writeln('Référence: ${order.paymentReference}');
    }
    buffer.writeln();

    // Amount breakdown
    buffer.writeln('MONTANTS');
    buffer.writeln('-' * 30);
    buffer.writeln('Montant: ${order.amount.toStringAsFixed(0)} FCFA');
    if (order.taxAmount > 0) {
      buffer.writeln('Taxes: ${order.taxAmount.toStringAsFixed(0)} FCFA');
    }
    buffer.writeln('=' * 30);
    buffer.writeln('TOTAL: ${order.totalAmount.toStringAsFixed(0)} FCFA');
    buffer.writeln('=' * 30);
    buffer.writeln();

    // Footer
    buffer.writeln('Merci pour votre confiance!');
    buffer.writeln();
    buffer.writeln('Ce reçu constitue une preuve de paiement valide.');
    buffer.writeln('Date d\'émission: ${_formatDate(DateTime.now())}');

    return buffer.toString();
  }

  /// Generate receipt for display
  Future<Map<String, dynamic>> generateReceiptData(Order order) async {
    return {
      'orderNumber': order.orderNumber,
      'createdAt': _formatDate(order.createdAt),
      'paidAt': order.paidAt != null ? _formatDate(order.paidAt!) : null,
      'status': order.statusText,
      'formation': order.formation != null ? {
        'title': order.formation!.title,
        'description': order.formation!.description,
      } : null,
      'payment': {
        'method': order.paymentMethodText,
        'reference': order.paymentReference,
      },
      'amounts': {
        'subtotal': order.amount,
        'tax': order.taxAmount,
        'total': order.totalAmount,
      },
      'company': {
        'name': _appName,
        'address': _appAddress,
        'phone': _appPhone,
        'email': _appEmail,
      },
      'generatedAt': _formatDate(DateTime.now()),
    };
  }

  /// Share receipt as text (can be extended to PDF later)
  Future<void> shareReceipt(Order order) async {
    try {
      final receiptText = generateReceiptText(order);

      // For now, copy to clipboard
      await Clipboard.setData(ClipboardData(text: receiptText));

      // In the future, this can be extended to share as PDF or send via email
      return;
    } catch (e) {
      throw Exception('Erreur lors du partage du reçu: $e');
    }
  }

  /// Save receipt data (simplified version)
  Future<String> saveReceipt(Order order) async {
    try {
      final receiptText = generateReceiptText(order);

      // For now, just return the text
      // In the future, this can save to a file or generate PDF
      return receiptText;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du reçu: $e');
    }
  }

  /// Print receipt (placeholder - can be implemented with proper printer support)
  Future<void> printReceipt(Order order) async {
    try {
      // For now, this is a placeholder
      // In the future, this can integrate with platform-specific printing
      throw UnimplementedError('Impression non encore disponible');
    } catch (e) {
      throw Exception('Erreur lors de l\'impression du reçu: $e');
    }
  }

  /// Format date helper
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  /// Format time helper
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
}