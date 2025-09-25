import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GetEnroll1Screen extends StatelessWidget {
  const GetEnroll1Screen({super.key});

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
                _buildProgressLine(false),
                _buildProgressStep(false),
                _buildProgressLine(false),
                _buildProgressStep(false),
                _buildProgressLine(false),
                _buildProgressStep(false),
              ],
            ),

            SizedBox(height: screenHeight * 0.04),

            // Title
            Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            Text(
              'Entrez vos informations personnelles pour continuer',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: screenHeight * 0.04),

            // Form Fields
            _buildTextField(
              label: 'Prénom',
              hintText: 'Entrez votre prénom',
              screenWidth: screenWidth,
            ),

            SizedBox(height: screenHeight * 0.025),

            _buildTextField(
              label: 'Nom',
              hintText: 'Entrez votre nom',
              screenWidth: screenWidth,
            ),

            SizedBox(height: screenHeight * 0.025),

            _buildTextField(
              label: 'Email',
              hintText: 'Entrez votre email',
              keyboardType: TextInputType.emailAddress,
              screenWidth: screenWidth,
            ),

            SizedBox(height: screenHeight * 0.025),

            _buildTextField(
              label: 'Numéro de téléphone',
              hintText: 'Entrez votre numéro',
              keyboardType: TextInputType.phone,
              screenWidth: screenWidth,
            ),

            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/get-enroll-2');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'CONTINUER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

  Widget _buildTextField({
    required String label,
    required String hintText,
    required double screenWidth,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        TextField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: screenWidth * 0.04,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1E3A8A),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}