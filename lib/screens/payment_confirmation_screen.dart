import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import 'dart:async';

class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({super.key});

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen>
    with TickerProviderStateMixin {
  int? _orderId;
  String? _paymentReference;
  Order? _order;
  Timer? _statusCheckTimer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePayment();
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _initializePayment() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _orderId = args['orderId'];
      _paymentReference = args['paymentReference'];

      if (_orderId != null) {
        context.read<OrderProvider>().loadOrderDetails(_orderId!).then((success) {
          if (success && mounted) {
            setState(() {
              _order = context.read<OrderProvider>().currentOrder;
            });
            _startPaymentStatusCheck();
          }
        });
      }
    }
  }

  void _startPaymentStatusCheck() {
    if (_orderId != null && _paymentReference != null) {
      // Check payment status every 5 seconds for up to 3 minutes
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (timer.tick >= 36) { // 36 * 5 seconds = 3 minutes
          timer.cancel();
          return;
        }

        context.read<OrderProvider>().checkPaymentStatus(
          orderId: _orderId!,
          paymentReference: _paymentReference!,
        ).then((success) {
          if (success && mounted) {
            final order = context.read<OrderProvider>().currentOrder;
            if (order != null && order.isPaid) {
              setState(() {
                _order = order;
              });
              _animationController.forward();
              timer.cancel();
            }
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading) {
              return _buildLoadingScreen(screenWidth);
            }

            if (_order == null) {
              return _buildErrorScreen('Commande non trouvée', screenWidth);
            }

            if (_order!.isPaid) {
              return _buildSuccessScreen(_order!, screenWidth);
            } else if (_order!.isFailed) {
              return _buildFailureScreen(_order!, screenWidth);
            } else {
              return _buildPendingScreen(_order!, screenWidth);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 24),
          Text(
            'Vérification du paiement...',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Veuillez patienter pendant que nous vérifions votre paiement.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.036,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(Order order, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green[200]!, width: 2),
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green[600],
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Paiement réussi !',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Votre paiement a été traité avec succès.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 32),

          // Order details card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow('Commande', '#${order.orderNumber}', screenWidth),
                  const SizedBox(height: 12),
                  _buildDetailRow('Montant', '${order.totalAmount.toStringAsFixed(0)} FCFA', screenWidth),
                  const SizedBox(height: 12),
                  _buildDetailRow('Référence', _paymentReference ?? 'N/A', screenWidth),
                  const SizedBox(height: 12),
                  _buildDetailRow('Date', _formatDateTime(order.paidAt ?? DateTime.now()), screenWidth),
                  if (order.formation != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('Formation', order.formation!.title, screenWidth),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _navigateToMyCourses(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Accéder à mes cours',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _navigateToHome(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailureScreen(Order order, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red[200]!, width: 2),
            ),
            child: Icon(
              Icons.error,
              size: 80,
              color: Colors.red[600],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Paiement échoué',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Une erreur s\'est produite lors du traitement de votre paiement.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _retryPayment(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Réessayer le paiement',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _navigateToHome(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingScreen(Order order, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange[200]!, width: 2),
            ),
            child: Icon(
              Icons.schedule,
              size: 80,
              color: Colors.orange[600],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Paiement en cours...',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Votre paiement est en cours de traitement. Veuillez suivre les instructions sur votre téléphone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 32),

          // Instructions
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue[600],
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Vérifiez votre téléphone pour une notification\n'
                    '• Entrez votre code PIN pour confirmer\n'
                    '• Gardez cette page ouverte',
                    style: TextStyle(
                      fontSize: screenWidth * 0.036,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => _navigateToHome(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Fermer',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String message, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 32),
          Text(
            'Erreur',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _navigateToHome(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Retour à l\'accueil',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.036,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: screenWidth * 0.036,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} à '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  void _navigateToMyCourses() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/my-courses',
      (route) => false,
    );
  }

  void _retryPayment() {
    Navigator.pushReplacementNamed(
      context,
      '/payment',
      arguments: {'orderId': _orderId},
    );
  }
}