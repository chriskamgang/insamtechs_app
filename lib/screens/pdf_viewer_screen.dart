import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PDFViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PDFViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWebView();
    });
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage =
                  'Erreur de chargement du PDF: ${error.description}';
            });
          },
        ),
      );

    _loadPDF();
  }

  void _loadPDF() {
    // Handle both 'url' and 'pdfUrl' parameters from different sources
    String pdfUrl = widget.url;

    // Check if we're coming from the library screen which uses 'pdfUrl'
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('pdfUrl')) {
      pdfUrl = args['pdfUrl'] ?? widget.url;
    }

    if (pdfUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Aucun fichier PDF disponible';
      });
      return;
    }

    try {
      // Vérifier si l'URL est valide et accessible
      var cleanUrl = pdfUrl.trim();

      // Si l'URL commence par "/storage/" ou "/uploads/", ajouter l'URL de base
      if (cleanUrl.startsWith('/storage/') ||
          cleanUrl.startsWith('/uploads/')) {
        // Remplacer par l'URL complète du serveur (à adapter selon votre configuration)
        cleanUrl = 'http://192.168.1.196:8001/storage${cleanUrl.substring(9)}';
      } else if (!cleanUrl.startsWith('http://') &&
          !cleanUrl.startsWith('https://')) {
        // Si ce n'est pas une URL complète, essayer d'ajouter le domaine
        // Vérifier si le chemin commence par "Fasciclues" ou un chemin similaire
        if (cleanUrl.startsWith('/Fasciclues') ||
            cleanUrl.startsWith('Fasciclues')) {
          // Ajouter le préfixe /storage/ pour les fichiers de ce type
          if (cleanUrl.startsWith('/')) {
            cleanUrl = 'http://192.168.1.196:8001/storage$cleanUrl';
          } else {
            cleanUrl = 'http://192.168.1.196:8001/storage/$cleanUrl';
          }
        } else {
          // Pour les autres cas, assurer qu'il y a un '/' entre le port et le chemin
          if (cleanUrl.startsWith('/')) {
            cleanUrl = 'http://192.168.1.196:8001$cleanUrl';
          } else {
            cleanUrl = 'http://192.168.1.196:8001/$cleanUrl';
          }
        }
      }

      // Vérifier si l'URL se termine par .pdf ou contient un paramètre de type PDF
      if (!cleanUrl.toLowerCase().contains('.pdf') &&
          !cleanUrl.toLowerCase().contains('pdf') &&
          !cleanUrl.contains(
            '?',
          ) // certains liens PDF peuvent contenir des paramètres
          ) {
        // Si ce n'est pas clairement un PDF, on tente quand même
        print('⚠️ L\'URL ne semble pas être un PDF: $cleanUrl');
      }

      // Essayez d'abord de charger directement le PDF dans le webview
      // Si c'est un lien externe, il sera chargé directement aussi
      final directPdfUrl = cleanUrl;
      print('📄 Chargement direct du PDF depuis: $directPdfUrl');
      _webViewController.loadRequest(Uri.parse(directPdfUrl));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Erreur lors du chargement: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the title from arguments if available (for library screen)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    String displayTitle = widget.title;
    if (args != null && args.containsKey('title')) {
      displayTitle = args['title'] ?? widget.title;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1E3A8A),
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPDF),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'download':
                  _downloadPDF();
                  break;
                case 'share':
                  _sharePDF();
                  break;
                case 'info':
                  _showPDFInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Télécharger'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Partager'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Informations'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    return _buildPDFViewer();
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement du PDF...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Impossible de charger le document PDF',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPDF,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFViewer() {
    return WebViewWidget(controller: _webViewController);
  }

  Future<void> _downloadPDF() async {
    // Handle both 'url' and 'pdfUrl' parameters from different sources
    String pdfUrl = widget.url;

    // Check if we're coming from the library screen which uses 'pdfUrl'
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('pdfUrl')) {
      pdfUrl = args['pdfUrl'] ?? widget.url;
    }

    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL du PDF non disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ouverture du téléchargement de "${widget.title}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le lien de téléchargement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sharePDF() {
    // Handle both 'url' and 'pdfUrl' parameters from different sources
    String pdfUrl = widget.url;

    // Check if we're coming from the library screen which uses 'pdfUrl'
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('pdfUrl')) {
      pdfUrl = args['pdfUrl'] ?? widget.url;
    }

    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL du PDF non disponible pour le partage'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Copy URL to clipboard or share - for now just show the URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL du PDF: $pdfUrl'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Copier',
          onPressed: () {
            // Copy to clipboard would require additional package
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('URL copiée (fonctionnalité à implémenter)'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPDFInfo() {
    // Handle both 'url' and 'pdfUrl' parameters from different sources
    String pdfUrl = widget.url;

    // Check if we're coming from the library screen which uses 'pdfUrl'
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('pdfUrl')) {
      pdfUrl = args['pdfUrl'] ?? widget.url;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations du document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Titre', widget.title),
            const SizedBox(height: 8),
            _buildInfoRow('URL', pdfUrl),
            const SizedBox(height: 8),
            _buildInfoRow('Format', 'PDF'),
            const SizedBox(height: 8),
            _buildInfoRow('Statut', _hasError ? 'Erreur' : 'Chargé'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }
}
