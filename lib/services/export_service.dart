import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/exam.dart';

class ExportService {
  static Future<String> _getDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> exportUserProgress({
    required String userId,
    required String userName,
    required List<Map<String, dynamic>> progressData,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Progression Utilisateur'];

      // Headers
      final headers = [
        'Cours',
        'Instructeur',
        'Progression (%)',
        'Statut',
        'Date d\'inscription',
        'Dernière activité',
        'Temps total',
        'Modules complétés',
        'Note moyenne',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
        );
      }

      // Data rows
      for (int i = 0; i < progressData.length; i++) {
        final data = progressData[i];
        final rowIndex = i + 1;

        final values = [
          data['course_title'] ?? '',
          data['instructor_name'] ?? '',
          '${data['progress_percentage'] ?? 0}%',
          _getStatusLabel(data['status']),
          _formatDate(data['enrollment_date']),
          _formatDate(data['last_activity']),
          _formatDuration(data['total_time_minutes']),
          '${data['completed_modules'] ?? 0}/${data['total_modules'] ?? 0}',
          data['average_score'] != null ? '${data['average_score']}/20' : 'N/A',
        ];

        for (int j = 0; j < values.length; j++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
          cell.value = TextCellValue(values[j].toString());
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      // Save file
      final documentsPath = await _getDocumentsPath();
      final fileName = 'progression_${userName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '$documentsPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de l\'export de la progression: $e');
    }
  }

  static Future<String> exportCertificates({
    required String userId,
    required String userName,
    required List<Map<String, dynamic>> certificatesData,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Certificats'];

      // Headers
      final headers = [
        'Cours',
        'Instructeur',
        'Note obtenue',
        'Note minimale',
        'Statut',
        'Date d\'obtention',
        'Numéro de certificat',
        'Validité',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
        );
      }

      // Data rows
      for (int i = 0; i < certificatesData.length; i++) {
        final data = certificatesData[i];
        final rowIndex = i + 1;

        final values = [
          data['course_title'] ?? '',
          data['instructor_name'] ?? '',
          '${data['final_score'] ?? 0}/20',
          '${data['passing_score'] ?? 10}/20',
          data['is_passed'] == true ? 'Réussi' : 'Échoué',
          _formatDate(data['completion_date']),
          data['certificate_number'] ?? '',
          data['is_valid'] == true ? 'Valide' : 'Expiré',
        ];

        for (int j = 0; j < values.length; j++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
          cell.value = TextCellValue(values[j].toString());

          // Color coding for pass/fail
          if (j == 4) { // Status column
            // Color coding removed for compatibility
          }
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      // Save file
      final documentsPath = await _getDocumentsPath();
      final fileName = 'certificats_${userName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '$documentsPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de l\'export des certificats: $e');
    }
  }

  static Future<String> exportExamResults({
    required String userId,
    required String userName,
    required List<Map<String, dynamic>> examResults,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Résultats d\'Examens'];

      // Headers
      final headers = [
        'Cours',
        'Exam',
        'Date de passage',
        'Durée (min)',
        'Score obtenu',
        'Score maximal',
        'Pourcentage',
        'Statut',
        'Tentative',
        'Temps utilisé',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
        );
      }

      // Data rows
      for (int i = 0; i < examResults.length; i++) {
        final data = examResults[i];
        final rowIndex = i + 1;

        final score = data['score'] ?? 0;
        final maxScore = data['max_score'] ?? 20;
        final percentage = maxScore > 0 ? (score / maxScore * 100).round() : 0;

        final values = [
          data['course_title'] ?? '',
          data['exam_title'] ?? '',
          _formatDate(data['completed_at']),
          '${data['duration_minutes'] ?? 0}',
          '$score',
          '$maxScore',
          '$percentage%',
          data['is_passed'] == true ? 'Réussi' : 'Échoué',
          '${data['attempt_number'] ?? 1}',
          _formatDuration(data['time_spent_minutes']),
        ];

        for (int j = 0; j < values.length; j++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex));
          cell.value = TextCellValue(values[j].toString());

          // Color coding for pass/fail
          if (j == 7) { // Status column
            // Color coding removed for compatibility
          }
        }
      }

      // Auto-size columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      // Save file
      final documentsPath = await _getDocumentsPath();
      final fileName = 'resultats_examens_${userName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '$documentsPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de l\'export des résultats d\'examens: $e');
    }
  }

  static Future<void> shareExcelFile({
    required String filePath,
    required String fileName,
    String? subject,
    String? text,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Export INSAM LMS',
        text: text ?? 'Voici votre export de données INSAM LMS',
      );
    } catch (e) {
      throw Exception('Erreur lors du partage du fichier: $e');
    }
  }

  static Future<String> createMultiSheetReport({
    required String userId,
    required String userName,
    required Map<String, List<Map<String, dynamic>>> allData,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Remove default sheet
      excel.delete('Sheet1');

      // Create summary sheet
      _createSummarySheet(excel, userName, allData);

      // Create individual sheets for each data type
      if (allData['progress']?.isNotEmpty == true) {
        _createProgressSheet(excel, allData['progress']!);
      }

      if (allData['certificates']?.isNotEmpty == true) {
        _createCertificatesSheet(excel, allData['certificates']!);
      }

      if (allData['examResults']?.isNotEmpty == true) {
        _createExamResultsSheet(excel, allData['examResults']!);
      }

      // Save file
      final documentsPath = await _getDocumentsPath();
      final fileName = 'rapport_complet_${userName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '$documentsPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de la création du rapport complet: $e');
    }
  }

  static void _createSummarySheet(Excel excel, String userName, Map<String, List<Map<String, dynamic>>> allData) {
    final sheet = excel['Résumé'];

    // Title
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue('Rapport INSAM LMS - $userName');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
    );

    // Date
    final dateCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    dateCell.value = TextCellValue('Généré le: ${_formatDate(DateTime.now().toIso8601String())}');

    // Statistics
    int row = 3;
    final stats = _calculateStatistics(allData);

    for (final stat in stats.entries) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      labelCell.value = TextCellValue(stat.key);
      labelCell.cellStyle = CellStyle(bold: true);

      final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      valueCell.value = TextCellValue(stat.value.toString());

      row++;
    }

    // Auto-size columns
    sheet.setColumnAutoFit(0);
    sheet.setColumnAutoFit(1);
  }

  static void _createProgressSheet(Excel excel, List<Map<String, dynamic>> progressData) {
    // Implementation similar to exportUserProgress but as a sheet
    final sheet = excel['Progression'];
    // ... (same logic as exportUserProgress but directly to sheet)
  }

  static void _createCertificatesSheet(Excel excel, List<Map<String, dynamic>> certificatesData) {
    // Implementation similar to exportCertificates but as a sheet
    final sheet = excel['Certificats'];
    // ... (same logic as exportCertificates but directly to sheet)
  }

  static void _createExamResultsSheet(Excel excel, List<Map<String, dynamic>> examResults) {
    // Implementation similar to exportExamResults but as a sheet
    final sheet = excel['Examens'];
    // ... (same logic as exportExamResults but directly to sheet)
  }

  static Map<String, dynamic> _calculateStatistics(Map<String, List<Map<String, dynamic>>> allData) {
    final progress = allData['progress'] ?? [];
    final certificates = allData['certificates'] ?? [];
    final examResults = allData['examResults'] ?? [];

    return {
      'Nombre de cours suivis': progress.length,
      'Cours complétés': progress.where((p) => p['status'] == 'completed').length,
      'Progression moyenne': progress.isNotEmpty
          ? '${(progress.map((p) => p['progress_percentage'] ?? 0).reduce((a, b) => a + b) / progress.length).round()}%'
          : '0%',
      'Certificats obtenus': certificates.where((c) => c['is_passed'] == true).length,
      'Examens passés': examResults.length,
      'Taux de réussite aux examens': examResults.isNotEmpty
          ? '${(examResults.where((e) => e['is_passed'] == true).length / examResults.length * 100).round()}%'
          : '0%',
    };
  }

  static String _getStatusLabel(String? status) {
    switch (status) {
      case 'enrolled':
        return 'Inscrit';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'paused':
        return 'En pause';
      default:
        return 'Inconnu';
    }
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  static String _formatDuration(int? minutes) {
    if (minutes == null) return 'N/A';
    if (minutes < 60) return '${minutes}min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h${remainingMinutes.toString().padLeft(2, '0')}min';
  }
}