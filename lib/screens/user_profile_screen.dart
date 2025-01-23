import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:library_book_management/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:library_book_management/services/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  static const routeName = '/user-profile';

  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;

  int _tapCount = 0;
  final int _easterEggThreshold = 7;
  final Duration _resetDuration = Duration(seconds: 2);

  void _handleAvatarTap(BuildContext context) {
    _tapCount++;

    final message = _tapCount < _easterEggThreshold
        ? 'Keep going! ${_easterEggThreshold - _tapCount} taps left!'
        : 'Easter Egg Unlocked! 🎉';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 500),
      ),
    );

    if (_tapCount >= _easterEggThreshold) {
      _tapCount = 0;
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      _showEasterEggPopup(context, isDarkMode);
    }

    Future.delayed(_resetDuration, () {
      if (_tapCount < _easterEggThreshold) {
        setState(() {
          _tapCount = 0;
        });
      }
    });
  }

  void _showEasterEggPopup(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/Images/easter egg.png',
                  height: 120, width: 120),
              const SizedBox(height: 16),
              const Text(
                '🎉 Congratulations! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You found the Easter Egg!',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user logged in");
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.email)
        .get();

    if (!userDoc.exists) {
      throw Exception("User data not found");
    }

    return userDoc.data()!;
  }

  Future<void> _updateName(BuildContext context, String currentFirstName,
      String currentLastName) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    final TextEditingController firstNameController =
        TextEditingController(text: currentFirstName);
    final TextEditingController lastNameController =
        TextEditingController(text: currentLastName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Name'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                if (firstNameController.text.isNotEmpty &&
                    lastNameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.email)
                      .update({
                    'firstName': firstNameController.text,
                    'lastName': lastNameController.text,
                  });

                  setState(() {
                    _userDataFuture = _fetchUserData();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated successfully')),
                  );
                  Navigator.of(context, rootNavigator: true).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in both fields')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update name: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context,
      GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Fluttertoast.showToast(
        msg: 'No user logged in',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool isOldPasswordVisible = false;
    bool isNewPasswordVisible = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Old Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        isOldPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          isOldPasswordVisible = !isOldPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !isOldPasswordVisible,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        isNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          isNewPasswordVisible = !isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !isNewPasswordVisible,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (oldPasswordController.text.isEmpty ||
                      newPasswordController.text.isEmpty) {
                    Fluttertoast.showToast(
                      msg: 'Please fill in both old and new password fields',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                    return;
                  }

                  if (!isValidPassword(newPasswordController.text)) {
                    Fluttertoast.showToast(
                      msg: 'New password is not strong enough.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                    return;
                  }

                  try {
                    await AuthService.reauthenticateUser(
                        user.email!, oldPasswordController.text);

                    await AuthService.changePassword(
                        newPasswordController.text, scaffoldMessengerKey);

                    Fluttertoast.showToast(
                      msg: 'Password changed successfully',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );

                    Navigator.of(context, rootNavigator: true).pop();

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);

                    _redirectToLoginScreen(context);
                  } on Exception catch (e) {
                    Fluttertoast.showToast(
                      msg: 'Error: ${e.toString()}',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                },
                child: const Text('Change'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _redirectToLoginScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  bool isValidPassword(String password) {
    final RegExp passwordRegExp = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return passwordRegExp.hasMatch(password);
  }

  Future<void> _forgotPassword(BuildContext context) async {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot Password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
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

                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send reset email: $e')),
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
      ),
    );
  }


  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Fluttertoast.showToast(
        msg: 'No user logged in',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    bool isReauthenticated = false;

    void _showReauthenticationDialog(
        BuildContext context, User user, VoidCallback onSuccess) {
      final TextEditingController passwordController = TextEditingController();
      bool isPasswordVisible = false;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Reauthenticate'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.deepPurpleAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    final userCredential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                    await user.reauthenticateWithCredential(userCredential);

                    Fluttertoast.showToast(
                      msg: 'Reauthenticated successfully',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );

                    onSuccess();
                    Navigator.of(context, rootNavigator: true).pop();
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: 'Reauthentication failed: $e',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                },
                child: const Text('Reauthenticate'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    }

    void _showDeleteConfirmationDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () async {
                if (!isReauthenticated) {
                  _showReauthenticationDialog(context, user, () {
                    isReauthenticated = true;
                    Navigator.of(context, rootNavigator: true).pop();
                    _showDeleteConfirmationDialog();
                  });
                } else {
                  try {
                    Fluttertoast.showToast(
                      msg: 'Your account is being deleted...',
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                    );

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .delete();
                    await user.delete();

                    Navigator.of(context, rootNavigator: true).pop();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);

                    await FirebaseAuth.instance.signOut();

                    Fluttertoast.showToast(
                      msg: 'Account deleted successfully',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );

                    Navigator.of(context).pushReplacementNamed('/login');
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: 'Failed to delete account: $e',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    _showDeleteConfirmationDialog();
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);

        await FirebaseAuth.instance.signOut();

        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget buildHeroSection(BuildContext context, bool isDarkMode) {
      return Hero(
        tag: 'card_View Profile',
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.black, Colors.grey.shade900]
                    : [
                        Colors.deepPurpleAccent.shade700,
                        Colors.deepPurpleAccent.shade400
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: const Stack(
              children: [
                Positioned(
                  bottom: 30,
                  left: 15,
                  child: Text(
                    'User Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.5,
                    child: Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
        GlobalKey<ScaffoldMessengerState>();

    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [Colors.black, Colors.grey.shade900]
                        : [
                            Colors.deepPurpleAccent.shade700,
                            Colors.deepPurpleAccent.shade400
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: 35,
                left: 15,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              buildHeroSection(context, isDarkMode),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _userDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final userData = snapshot.data!;
                    final GlobalKey<ScaffoldMessengerState>
                        scaffoldMessengerKey =
                        GlobalKey<ScaffoldMessengerState>();
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _handleAvatarTap(context),
                                  child: CircleAvatar(
                                    radius: 80,
                                    backgroundColor: Colors.deepPurpleAccent,
                                    child: userData['profileImage'] == null ||
                                            userData['profileImage'] == ''
                                        ? const Icon(Icons.account_circle,
                                            size: 100, color: Colors.white)
                                        : ClipOval(
                                            child: Image.network(
                                              userData['profileImage'],
                                              width: 160,
                                              height: 160,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${userData['firstName']} ${userData['lastName']}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.deepPurpleAccent),
                                      onPressed: () => _updateName(
                                        context,
                                        userData['firstName'] ?? '',
                                        userData['lastName'] ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Email: ${userData['email']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Member since: ${_formatDate(userData['createdAt'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ActionButtonCard(
                                  icon: Icons.lock,
                                  label: 'Change Password',
                                  color: Colors.deepPurpleAccent,
                                  onPressed: () => _changePassword(
                                      context, scaffoldMessengerKey),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ActionButtonCard(
                                  icon: Icons.refresh,
                                  label: 'Forgot Password',
                                  color: Colors.orangeAccent,
                                  onPressed: () => _forgotPassword(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ActionButtonCard(
                                  icon: Icons.delete,
                                  label: 'Delete Account',
                                  color: Colors.redAccent,
                                  onPressed: () => _deleteAccount(context),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ActionButtonCard(
                                  icon: Icons.exit_to_app,
                                  label: 'Logout',
                                  color: Colors.grey,
                                  onPressed: () => _logout(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButtonCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const ActionButtonCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(Timestamp timestamp) {
  final DateTime date = timestamp.toDate();
  final DateFormat formatter = DateFormat('dd MMM yyyy h:mm a');
  return formatter.format(date);
}
