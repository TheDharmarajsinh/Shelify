import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:library_book_management/screens/registration_screen.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Color get primaryColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF202849);

  Color get secondaryTextColor =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white70
          : Colors.grey[600]!;

  Color get textFieldFillColor =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[50]!;

  Color get checkboxActiveColor =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF202849);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('email') ?? '';
    passwordController.text = prefs.getString('password') ?? '';
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Images/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please sign in to your account.',
                    style: TextStyle(fontSize: 16, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 40),
                  _buildTextFormField(
                    controller: emailController,
                    labelText: 'Email Address',
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordTextFormField(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: checkboxActiveColor,
                          ),
                          const Text('Remember Me'),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showForgotPasswordDialog(context),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : primaryColor,
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
                        : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const RegistrationScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(-1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                final tween =
                                    Tween(begin: begin, end: end).chain(
                                  CurveTween(curve: curve),
                                );
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
                          'Register here',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                      ),
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

  Widget _buildPasswordTextFormField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: primaryColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: textFieldFillColor,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: primaryColor,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: _validatePassword,
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: primaryColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: textFieldFillColor,
      ),
      validator: validator,
    );
  }

  String? _validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = emailController.text;
      String password = passwordController.text;

      try {
        await AuthService.login(email, password);

        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await _saveCredentials();
            Navigator.pushReplacementNamed(context, HomeScreen.routeName);
          } else {
            _showEmailNotVerifiedDialog();
          }
        } else {
          throw Exception('No user found');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Forgot Password'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@domain.com',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                String email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter your email address')),
                  );
                } else {
                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    Fluttertoast.showToast(
                      msg: "Password reset email sent. Check your inbox.",
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                    );
                    Navigator.of(context, rootNavigator: true).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Send Reset Link'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Not Verified'),
          content:
              const Text('Please verify your email address and try again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
