import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GetEnroll3Screen extends StatefulWidget {
  const GetEnroll3Screen({super.key});

  @override
  State<GetEnroll3Screen> createState() => _GetEnroll3ScreenState();
}

class _GetEnroll3ScreenState extends State<GetEnroll3Screen> {
  String? selectedPaymentMethod;
  bool acceptTerms = false;
  bool acceptPrivacy = false;

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      name: 'Carte de crédit',
      icon: Icons.credit_card,
      subtitle: 'Visa, Mastercard, American Express',
    ),
    PaymentMethod(
      name: 'PayPal',
      icon: Icons.account_balance_wallet,
      subtitle: 'Paiement sécurisé via PayPal',
    ),
    PaymentMethod(
      name: 'Virement bancaire',
      icon: Icons.account_balance,
      subtitle: 'Transfert bancaire direct',
    ),
    PaymentMethod(
      name: 'Mobile Money',
      icon: Icons.phone_android,
      subtitle: 'Orange Money, MTN Money',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),

            // Progress Indicator
            Row(
              children: [
                _buildProgressStep(true),
                _buildProgressLine(true),
                _buildProgressStep(true),
                _buildProgressLine(true),
                _buildProgressStep(true),
                _buildProgressLine(false),
                _buildProgressStep(false),
              ],
            ),

            SizedBox(height: screenHeight * 0.04),

            // Title
            Text(
              'Méthode de paiement',
              style: TextStyle(
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            Text(
              'Choisissez votre méthode de paiement préférée',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: screenHeight * 0.04),

            // Payment Methods
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...paymentMethods.map((method) {
                      return _buildPaymentMethodCard(method, screenWidth);
                    }),

                    SizedBox(height: screenHeight * 0.03),

                    // Course Summary
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résumé de la commande',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cours: Graphic Design',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '72€',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Frais de traitement',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '3€',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: screenWidth * 0.06),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '75€',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Terms and Conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              acceptTerms = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1E3A8A),
                        ),
                        Expanded(
                          child: Text(
                            'J\'accepte les conditions générales d\'utilisation',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: acceptPrivacy,
                          onChanged: (value) {
                            setState(() {
                              acceptPrivacy = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1E3A8A),
                        ),
                        Expanded(
                          child: Text(
                            'J\'accepte la politique de confidentialité',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: selectedPaymentMethod != null && acceptTerms && acceptPrivacy
                    ? () {
                        Navigator.pushNamed(context, '/get-enroll-4');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'PROCÉDER AU PAIEMENT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: selectedPaymentMethod != null && acceptTerms && acceptPrivacy
                        ? Colors.white
                        : Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(bool isActive) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: isActive
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
          : null,
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[300],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, double screenWidth) {
    final isSelected = selectedPaymentMethod == method.name;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPaymentMethod = method.name;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A).withValues(alpha: 0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  method.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      method.subtitle,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: method.name,
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value;
                  });
                },
                activeColor: const Color(0xFF1E3A8A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentMethod {
  final String name;
  final IconData icon;
  final String subtitle;

  PaymentMethod({
    required this.name,
    required this.icon,
    required this.subtitle,
  });
}