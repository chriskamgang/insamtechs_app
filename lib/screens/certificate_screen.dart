import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/certificate.dart';
import '../providers/auth_provider.dart';
import '../services/exam_service.dart';

class CertificateScreen extends StatefulWidget {
  final int tentativeId;
  final String formationTitle;

  const CertificateScreen({
    super.key,
    required this.tentativeId,
    required this.formationTitle,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with TickerProviderStateMixin {
  Certificate? _certificate;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCertificate();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  Future<void> _loadCertificate() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || authProvider.user?.id == null) {
      setState(() {
        _errorMessage = 'Utilisateur non authentifié';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ExamService().getCertificate(
        widget.tentativeId,
        authProvider.user!.id!,
      );

      if (response['success']) {
        final certificate = ExamService().parseCertificate(response['data']);
        setState(() {
          _certificate = certificate;
          _isLoading = false;
        });

        // Start animations
        _fadeController.forward();
        _slideController.forward();
      } else {
        setState(() {
          _errorMessage = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du certificat: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Certificat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_certificate != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareCertificate,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildCertificateContent(screenWidth, screenHeight),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCertificate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateContent(double screenWidth, double screenHeight) {
    if (_certificate == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildCertificateCard(screenWidth, screenHeight),
              const SizedBox(height: 24),
              _buildActionButtons(screenWidth),
              const SizedBox(height: 24),
              _buildCertificateDetails(screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateCard(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
            Color(0xFF60A5FA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Certificate content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),

                Text(
                  'CERTIFICAT DE RÉUSSITE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Recipient
                Text(
                  'Décerné à',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _certificate!.userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Achievement
                Text(
                  'Pour avoir réussi avec succès',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: screenWidth * 0.035,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  _certificate!.formationTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Score: ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                    Text(
                      _certificate!.displayScore,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Date and certificate number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                        Text(
                          '${_certificate!.dateObtention.day}/${_certificate!.dateObtention.month}/${_certificate!.dateObtention.year}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'N° Certificat',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                        Text(
                          _certificate!.certificateCode,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _downloadCertificate,
            icon: const Icon(Icons.download),
            label: const Text('Télécharger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareCertificate,
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF1E3A8A)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateDetails(double screenWidth) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails du certificat',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailRow('Formation', _certificate!.formationTitle),
            _buildDetailRow('Bénéficiaire', _certificate!.userName),
            _buildDetailRow('Score obtenu', '${_certificate!.scoreObtenu.toStringAsFixed(1)}%'),
            _buildDetailRow('Note de passage', '${_certificate!.notePassage.toStringAsFixed(1)}%'),
            _buildDetailRow('Date d\'obtention', '${_certificate!.dateObtention.day}/${_certificate!.dateObtention.month}/${_certificate!.dateObtention.year}'),
            _buildDetailRow('Numéro de certificat', _certificate!.certificateCode),
            _buildDetailRow('Statut', _certificate!.statusText),

            if (_certificate!.dateExpiration != null)
              _buildDetailRow('Date d\'expiration', '${_certificate!.dateExpiration!.day}/${_certificate!.dateExpiration!.month}/${_certificate!.dateExpiration!.year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadCertificate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement du certificat...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implement PDF download
  }

  void _shareCertificate() {
    Clipboard.setData(ClipboardData(
      text: 'J\'ai obtenu mon certificat pour "${_certificate!.formationTitle}" avec un score de ${_certificate!.scoreObtenu.toStringAsFixed(1)}%! Code de vérification: ${_certificate!.certificateCode}',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informations du certificat copiées!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}