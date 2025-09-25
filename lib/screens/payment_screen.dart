import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  PaymentMethod? _selectedPaymentMethod;
  int? _orderId;
  Order? _order;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrder();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeOrder() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _orderId = args['orderId'];
      if (_orderId != null) {
        context.read<OrderProvider>().loadOrderDetails(_orderId!).then((success) {
          if (success && mounted) {
            setState(() {
              _order = context.read<OrderProvider>().currentOrder;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paiement',
          style: TextStyle(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_order == null) {
            return const Center(
              child: Text('Commande non trouvée'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  _buildOrderSummary(_order!, screenWidth),

                  const SizedBox(height: 24),

                  // Payment methods
                  _buildPaymentMethods(screenWidth),

                  const SizedBox(height: 24),

                  // Phone number input (for mobile money)
                  if (_selectedPaymentMethod == PaymentMethod.mobileMoneyMTN ||
                      _selectedPaymentMethod == PaymentMethod.mobileMoneyOrange)
                    _buildPhoneNumberInput(screenWidth),

                  const SizedBox(height: 32),

                  // Payment button
                  _buildPaymentButton(orderProvider, screenWidth),

                  const SizedBox(height: 16),

                  // Security notice
                  _buildSecurityNotice(screenWidth),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(Order order, double screenWidth) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la commande',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Formation details
            if (order.formation != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.school,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.formation!.title,
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Order number
            Row(
              children: [
                Icon(
                  Icons.receipt,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Commande #${order.orderNumber}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Amount breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Montant',
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${order.amount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            if (order.taxAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taxes',
                    style: TextStyle(
                      fontSize: screenWidth * 0.036,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${order.taxAmount.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: screenWidth * 0.036,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total à payer',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods(double screenWidth) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Méthode de paiement',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // MTN Mobile Money
            _buildPaymentMethodTile(
              PaymentMethod.mobileMoneyMTN,
              'MTN Mobile Money',
              Icons.phone_android,
              Colors.yellow[700]!,
              screenWidth,
            ),

            const SizedBox(height: 12),

            // Orange Money
            _buildPaymentMethodTile(
              PaymentMethod.mobileMoneyOrange,
              'Orange Money',
              Icons.phone_android,
              Colors.orange[700]!,
              screenWidth,
            ),

            const SizedBox(height: 12),

            // Bank Transfer
            _buildPaymentMethodTile(
              PaymentMethod.bankTransfer,
              'Virement bancaire',
              Icons.account_balance,
              Colors.blue[700]!,
              screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    String title,
    IconData icon,
    Color color,
    double screenWidth,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFF1E3A8A).withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1E3A8A),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberInput(double screenWidth) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Numéro de téléphone',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Ex: 237xxxxxxxx',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E3A8A),
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                if (value.length < 9) {
                  return 'Numéro de téléphone invalide';
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            Text(
              'Entrez le numéro associé à votre compte ${_selectedPaymentMethod == PaymentMethod.mobileMoneyMTN ? 'MTN' : 'Orange'} Money',
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(OrderProvider orderProvider, double screenWidth) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _canProceedPayment(orderProvider) ? _processPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 3,
        ),
        child: orderProvider.isPaymentLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Procéder au paiement',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSecurityNotice(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vos informations de paiement sont sécurisées et cryptées.',
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedPayment(OrderProvider orderProvider) {
    if (orderProvider.isPaymentLoading) return false;
    if (_selectedPaymentMethod == null) return false;
    if (_order == null) return false;

    // For mobile money, phone number is required
    if ((_selectedPaymentMethod == PaymentMethod.mobileMoneyMTN ||
         _selectedPaymentMethod == PaymentMethod.mobileMoneyOrange) &&
        _phoneController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final orderProvider = context.read<OrderProvider>();

    final success = await orderProvider.processPayment(
      orderId: _order!.id,
      paymentMethod: _selectedPaymentMethod!,
      phoneNumber: _phoneController.text.trim(),
    );

    if (success && mounted) {
      // Navigate to payment confirmation or success screen
      Navigator.pushReplacementNamed(
        context,
        '/payment-confirmation',
        arguments: {
          'orderId': _order!.id,
          'paymentReference': orderProvider.paymentReference,
        },
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.paymentError ?? 'Erreur lors du paiement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}