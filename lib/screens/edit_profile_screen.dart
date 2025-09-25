import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      _nameController.text = user.nom;
      _surnameController.text = user.prenom;
      _emailController.text = user.email ?? '';
      _phoneController.text = user.telephone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final user = authProvider.user;

    if (user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation du mot de passe si renseigné
    if (_showPasswordFields && _passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les mots de passe ne correspondent pas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le mot de passe doit contenir au moins 6 caractères'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final updatedUser = await userProvider.updateProfile(
      userId: user!.id!,
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      tel: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _showPasswordFields && _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
    );

    if (mounted) {
      if (userProvider.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.successMessage!),
            backgroundColor: Colors.green,
          ),
        );

        // Mettre à jour les données de l'utilisateur dans AuthProvider
        if (updatedUser != null) {
          authProvider.updateUserData(updatedUser);
        }

        // Revenir à l'écran précédent
        Navigator.pop(context);
      } else if (userProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text('Modifier le profil'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nom',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Prénom
                  _buildTextField(
                    controller: _surnameController,
                    label: 'Prénom',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le prénom est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'email est obligatoire';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Téléphone
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le téléphone est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Option pour changer le mot de passe
                  Row(
                    children: [
                      Checkbox(
                        value: _showPasswordFields,
                        onChanged: (value) {
                          setState(() {
                            _showPasswordFields = value ?? false;
                            if (!_showPasswordFields) {
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                            }
                          });
                        },
                        activeColor: const Color(0xFF1E3A8A),
                      ),
                      const Text('Changer le mot de passe'),
                    ],
                  ),

                  // Champs mot de passe (conditionnels)
                  if (_showPasswordFields) ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Nouveau mot de passe',
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      validator: _showPasswordFields
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le mot de passe est obligatoire';
                              }
                              if (value.length < 6) {
                                return 'Le mot de passe doit contenir au moins 6 caractères';
                              }
                              return null;
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmer le mot de passe',
                      obscureText: !_isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      validator: _showPasswordFields
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirmez votre mot de passe';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            }
                          : null,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Bouton de sauvegarde
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: userProvider.isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: userProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}