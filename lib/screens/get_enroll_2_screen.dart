import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GetEnroll2Screen extends StatefulWidget {
  const GetEnroll2Screen({super.key});

  @override
  State<GetEnroll2Screen> createState() => _GetEnroll2ScreenState();
}

class _GetEnroll2ScreenState extends State<GetEnroll2Screen> {
  String? selectedEducationLevel;
  String? selectedExperience;

  final List<String> educationLevels = [
    'Lycée',
    'Baccalauréat',
    'Licence',
    'Master',
    'Doctorat',
    'Autre',
  ];

  final List<String> experienceLevels = [
    'Débutant',
    '1-2 ans',
    '3-5 ans',
    '5+ ans',
    'Expert',
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
                _buildProgressLine(false),
                _buildProgressStep(false),
                _buildProgressLine(false),
                _buildProgressStep(false),
              ],
            ),

            SizedBox(height: screenHeight * 0.04),

            // Title
            Text(
              'Informations académiques',
              style: TextStyle(
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            Text(
              'Partagez votre parcours éducatif et votre niveau d\'expérience',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: screenHeight * 0.04),

            // Education Level
            Text(
              'Niveau d\'éducation',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: screenWidth * 0.02),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedEducationLevel,
                  hint: Text(
                    'Sélectionnez votre niveau',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  isExpanded: true,
                  items: educationLevels.map((String level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedEducationLevel = newValue;
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Experience Level
            Text(
              'Niveau d\'expérience',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: screenWidth * 0.02),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedExperience,
                  hint: Text(
                    'Sélectionnez votre expérience',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  isExpanded: true,
                  items: experienceLevels.map((String level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedExperience = newValue;
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Additional Information
            Text(
              'Informations supplémentaires (optionnel)',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: screenWidth * 0.02),

            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Parlez-nous de vos objectifs et motivations...',
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
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: selectedEducationLevel != null && selectedExperience != null
                    ? () {
                        Navigator.pushNamed(context, '/get-enroll-3');
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
                  'CONTINUER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selectedEducationLevel != null && selectedExperience != null
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
}