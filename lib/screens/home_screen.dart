import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_book_management/screens/registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'audio_books_screen.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';
import 'borrow_book_screen.dart';
import 'favorite_books_screen.dart';

const Color lightPrimaryColor = Color(0xFF202849);
const Color darkPrimaryColor = Color(0xFF181B2A);
const Color backgroundGradientStartLight = Color(0xFFEFEFF4);
const Color backgroundGradientEndLight = Color(0xFFFFFFFF);
const Color backgroundGradientStartDark = Color(0xFF000000);
const Color backgroundGradientEndDark = Color(0xFF000000);

final lightTheme = ThemeData(
  brightness: Brightness.light,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
);

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        BorrowBookScreen.routeName: (context) => const BorrowBookScreen(),
        FavoriteBooksScreen.routeName: (context) => const FavoriteBooksScreen(),
        UserProfileScreen.routeName: (context) => const UserProfileScreen(),
        AudioBooksScreen.routeName: (context) => const AudioBooksScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegistrationScreen.routeName: (context) => RegistrationScreen(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeHomePage();
  }

  Future<void> _initializeHomePage() async {
    await _checkAuthenticationStatus();
    await _fetchUserName();
  }

  Future<void> _checkAuthenticationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getString('saved_email');
    prefs.getString('saved_password');
  }

  Future<void> _fetchUserName() async {
    try {
      User? user = AuthService.currentUser;

      if (user != null) {
        String userEmail = user.email ?? '';
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userData = userSnapshot.docs.first;

          setState(() {
            userName = userData['firstName'] ?? 'User';
          });
        } else {
          setState(() {
            userName = 'User';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      _navigateTo(context, LoginScreen.routeName);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.blueAccent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 6,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Fetching user data...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, theme, isDarkMode),
    );
  }

  @override
  bool get wantKeepAlive => true;

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Shelify Home', style: TextStyle(color: Colors.white)),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: _buildGradientBackground(isDarkMode),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(theme),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Quick Actions', theme),
                    const SizedBox(height: 12),
                    _buildGridSection(context, _getQuickActionCards(context)),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Explore', theme),
                    const SizedBox(height: 12),
                    _buildGridSection(context, _getExploreCards(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground(bool isDarkMode) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDarkMode
            ? [backgroundGradientStartDark, backgroundGradientEndDark]
            : [backgroundGradientStartLight, backgroundGradientEndLight],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    return Text(
      isLoading ? 'Hello, loading...' : 'Hello, $userName!',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color:
            theme.brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color:
            theme.brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildGridSection(BuildContext context, List<Widget> cards) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  List<Widget> _getQuickActionCards(BuildContext context) {
    return [
      _buildActionCard(
        context,
        title: 'Borrow Books',
        icon: Icons.book,
        description: 'Explore and borrow books.',
        routeName: BorrowBookScreen.routeName,
      ),
      _buildActionCard(
        context,
        title: 'Audio Books',
        icon: Icons.headset,
        description: 'Discover and listen to audio books.',
        routeName: AudioBooksScreen.routeName,
      ),
    ];
  }

  List<Widget> _getExploreCards(BuildContext context) {
    return [
      _buildActionCard(
        context,
        title: 'Favorite Books',
        icon: Icons.favorite,
        description: 'Your most loved books.',
        routeName: FavoriteBooksScreen.routeName,
      ),
      _buildActionCard(
        context,
        title: 'View Profile',
        icon: Icons.person,
        description: 'Manage your account.',
        routeName: UserProfileScreen.routeName,
      ),
    ];
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required String routeName,
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(routeName),
      child: Hero(
        tag: 'card_$title',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }
}
