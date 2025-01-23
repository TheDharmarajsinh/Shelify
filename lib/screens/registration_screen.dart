import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  static const routeName = '/registration';

  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _firstNameError;
  String? _lastNameError;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isFormSubmitted = false;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    setState(() {
      _isFormSubmitted = true;
    });

    _validateForm();
    if (!_isFormValid()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await userCredential.user?.sendEmailVerification();

      final userEmail = emailController.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'email': userEmail,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Registration successful! Please verify your email.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Images/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Create a New Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Color(0xFF202849),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please fill in the details to get started.',
                    style: TextStyle(
                        fontSize: 16,
                        color:
                            isDarkMode ? Colors.grey[300] : Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: firstNameController,
                    labelText: 'First Name',
                    errorText: _firstNameError,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: lastNameController,
                    labelText: 'Last Name',
                    errorText: _lastNameError,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: emailController,
                    labelText: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordTextField(
                    controller: passwordController,
                    labelText: 'Password',
                    errorText: _passwordError,
                    isPasswordVisible: _isPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordTextField(
                    controller: confirmPasswordController,
                    labelText: 'Confirm Password',
                    errorText: _confirmPasswordError,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading
                          ? Colors.grey
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : const Color(0xFF202849)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const LoginScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                final tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                final offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Text(
                          'Login here',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    required ValueChanged<String> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: _isFormSubmitted ? errorText : null,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String labelText,
    required String? errorText,
    required bool isPasswordVisible,
    required VoidCallback onVisibilityToggle,
    required ValueChanged<String> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: _isFormSubmitted ? errorText : null,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: onVisibilityToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
      ),
      onChanged: onChanged,
    );
  }

  void _validateForm() {
    setState(() {
      _emailError =
          _isValidEmail(emailController.text) ? null : 'Invalid email format';
      _passwordError = _isPasswordValid(passwordController.text)
          ? null
          : 'Password must be at least 8 characters,\ncontain an uppercase letter, a digit,\nand a special character';
      _confirmPasswordError =
          confirmPasswordController.text != passwordController.text
              ? 'Passwords do not match'
              : null;
      _firstNameError =
          firstNameController.text.isEmpty ? 'First name is required' : null;
      _lastNameError =
          lastNameController.text.isEmpty ? 'Last name is required' : null;
    });
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    final passwordRegExp = RegExp(
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$',
    );
    return passwordRegExp.hasMatch(password);
  }

  bool _isFormValid() {
    return _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _firstNameError == null &&
        _lastNameError == null;
  }

}
