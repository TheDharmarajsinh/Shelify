import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/audio_books_screen.dart';
import 'screens/audio_book_details_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/borrow_book_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'YOUR_API_KEY',
        appId: 'YOUR_APP_ID',
        messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        storageBucket: 'YOUR_STORAGE_BUCKET',
        authDomain: 'YOUR_AUTH_DOMAIN',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Library Book Management",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        RegistrationScreen.routeName: (context) => RegistrationScreen(),
        BookDetailsScreen.routeName: (context) => const BookDetailsScreen(
              bookId: '',
              book: {},
              bookData: {},
              onLikeStatusChanged: null,
            ),
        UserProfileScreen.routeName: (context) => const UserProfileScreen(),
        BorrowBookScreen.routeName: (context) => const BorrowBookScreen(),
        AudioBooksScreen.routeName: (context) => const AudioBooksScreen(),
        AudioBookDetailsScreen.routeName: (context) =>
            AudioBookDetailsScreen(book: {}, bookId: ''),
      },
    );
  }
}
