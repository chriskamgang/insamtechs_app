import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/export_service.dart';
import '../providers/auth_provider.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  bool _isExporting = false;
  String? _exportStatus;

  Future<void> _exportUserProgress() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Export de la progression en cours...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Simulation des données de progression
      final progressData = [
        {
          'course_title': 'Introduction au Flutter',
          'instructor_name': 'Dr. Jean Dupont',
          'progress_percentage': 85,
          'status': 'in_progress',
          'enrollment_date': '2024-01-15T10:00:00Z',
          'last_activity': '2024-01-20T15:30:00Z',
          'total_time_minutes': 240,
          'completed_modules': 8,
          'total_modules': 10,
          'average_score': 16.5,
        },
        {
          'course_title': 'Développement Web Avancé',
          'instructor_name': 'Prof. Marie Martin',
          'progress_percentage': 100,
          'status': 'completed',
          'enrollment_date': '2023-12-01T08:00:00Z',
          'last_activity': '2024-01-10T12:00:00Z',
          'total_time_minutes': 480,
          'completed_modules': 12,
          'total_modules': 12,
          'average_score': 18.2,
        },
      ];

      final filePath = await ExportService.exportUserProgress(
        userId: user.id.toString(),
        userName: '${user.prenom} ${user.nom}',
        progressData: progressData,
      );

      await ExportService.shareExcelFile(
        filePath: filePath,
        fileName: 'progression.xlsx',
        subject: 'Ma progression INSAM LMS',
        text: 'Voici le rapport de votre progression sur INSAM LMS.',
      );

      setState(() {
        _exportStatus = 'Export terminé avec succès !';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progression exportée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _exportStatus = 'Erreur: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportCertificates() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Export des certificats en cours...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Simulation des données de certificats
      final certificatesData = [
        {
          'course_title': 'Développement Web Avancé',
          'instructor_name': 'Prof. Marie Martin',
          'final_score': 18.2,
          'passing_score': 10,
          'is_passed': true,
          'completion_date': '2024-01-10T12:00:00Z',
          'certificate_number': 'INSAM-2024-001234',
          'is_valid': true,
        },
        {
          'course_title': 'JavaScript ES6+',
          'instructor_name': 'Dr. Paul Durand',
          'final_score': 15.5,
          'passing_score': 10,
          'is_passed': true,
          'completion_date': '2023-11-15T14:30:00Z',
          'certificate_number': 'INSAM-2023-005678',
          'is_valid': true,
        },
      ];

      final filePath = await ExportService.exportCertificates(
        userId: user.id.toString(),
        userName: '${user.prenom} ${user.nom}',
        certificatesData: certificatesData,
      );

      await ExportService.shareExcelFile(
        filePath: filePath,
        fileName: 'certificats.xlsx',
        subject: 'Mes certificats INSAM LMS',
        text: 'Voici vos certificats obtenus sur INSAM LMS.',
      );

      setState(() {
        _exportStatus = 'Export terminé avec succès !';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificats exportés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _exportStatus = 'Erreur: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportExamResults() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Export des résultats d\'examens en cours...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Simulation des données d'examens
      final examResults = [
        {
          'course_title': 'Développement Web Avancé',
          'exam_title': 'Examen Final',
          'completed_at': '2024-01-10T11:00:00Z',
          'duration_minutes': 120,
          'score': 18.2,
          'max_score': 20,
          'is_passed': true,
          'attempt_number': 1,
          'time_spent_minutes': 105,
        },
        {
          'course_title': 'Introduction au Flutter',
          'exam_title': 'Quiz Module 5',
          'completed_at': '2024-01-18T16:30:00Z',
          'duration_minutes': 30,
          'score': 14.5,
          'max_score': 20,
          'is_passed': true,
          'attempt_number': 2,
          'time_spent_minutes': 28,
        },
      ];

      final filePath = await ExportService.exportExamResults(
        userId: user.id.toString(),
        userName: '${user.prenom} ${user.nom}',
        examResults: examResults,
      );

      await ExportService.shareExcelFile(
        filePath: filePath,
        fileName: 'resultats_examens.xlsx',
        subject: 'Mes résultats d\'examens INSAM LMS',
        text: 'Voici vos résultats d\'examens sur INSAM LMS.',
      );

      setState(() {
        _exportStatus = 'Export terminé avec succès !';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Résultats d\'examens exportés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _exportStatus = 'Erreur: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final exportOptions = [
      ExportOption(
        title: l10n.exportProgress,
        description: 'Exportez votre progression dans tous vos cours',
        icon: Icons.trending_up,
        color: const Color(0xFF1E3A8A),
        onTap: _exportUserProgress,
      ),
      ExportOption(
        title: l10n.exportCertificates,
        description: 'Exportez la liste de vos certificats obtenus',
        icon: Icons.workspace_premium,
        color: Colors.amber[800]!,
        onTap: _exportCertificates,
      ),
      ExportOption(
        title: l10n.exportResults,
        description: 'Exportez vos résultats d\'examens et quiz',
        icon: Icons.quiz,
        color: Colors.green[700]!,
        onTap: _exportExamResults,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.export,
          style: TextStyle(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.file_download,
                        color: const Color(0xFF1E3A8A),
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          l10n.downloadExcel,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    'Exportez vos données personnelles au format Excel pour un suivi détaillé de votre parcours d\'apprentissage.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Export Options
            Text(
              'Options d\'export',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),

            ...exportOptions.map((option) => _buildExportTile(option, screenWidth)),

            SizedBox(height: screenHeight * 0.03),

            // Status Display
            if (_exportStatus != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: _exportStatus!.contains('Erreur')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _exportStatus!.contains('Erreur')
                        ? Colors.red[200]!
                        : Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _exportStatus!.contains('Erreur')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _exportStatus!.contains('Erreur')
                          ? Colors.red[700]
                          : Colors.green[700],
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        _exportStatus!,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: _exportStatus!.contains('Erreur')
                              ? Colors.red[700]
                              : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
            ],

            // Info Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: screenWidth * 0.05,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Informations',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  Text(
                    '• Les fichiers Excel sont sauvegardés localement\n'
                    '• Vous pouvez partager directement via WhatsApp, email, etc.\n'
                    '• Les données incluent tous vos cours et résultats\n'
                    '• Format compatible avec Excel, Google Sheets, LibreOffice',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                      height: 1.5,
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

  Widget _buildExportTile(ExportOption option, double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: _isExporting ? null : option.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option.icon,
                  color: option.color,
                  size: screenWidth * 0.06,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isExporting)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(option.color),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExportOption {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ExportOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}