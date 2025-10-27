import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Settings
import 'package:firebase_auth/firebase_auth.dart'; // For auth state listener
import 'home_screen.dart'; // Import the new HomeScreen file
import 'screens/login_screen.dart'; // Adjust path if LoginScreen is elsewhere (e.g., 'login_screen.dart')

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully'); // Debug: Confirm init
  } catch (e) {
    print('Firebase init error: $e'); // Log failure
    // Fallback: App runs without Firebase (shows white screen otherwise)
  }
 
  // Disable persistence to force server fetches (fixes stale cache for new fields like description)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  // Explicitly set auth persistence to LOCAL for Android/Samsung reliability
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print('Auth persistence set to LOCAL'); // Debug
  } catch (e) {
    print('Auth persistence error: $e'); // Log if fails
  }
 
  runApp(const DanfelsApp());
}

class DanfelsApp extends StatelessWidget {
  const DanfelsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Danfels',
      theme: ThemeData(
        primarySwatch: Colors.lime, // Lime green primary
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF32CD32), // Lime green
          onPrimary: Colors.black, // Black on lime
          secondary: Colors.black, // Black secondary
          onSecondary: Colors.white, // White on black
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white, // White background
          onSurface: Colors.black, // Black text
          background: Colors.white,
          onBackground: Colors.black,
          outline: Colors.black26,
          onInverseSurface: Colors.white,
          inverseSurface: Colors.black,
          shadow: Colors.black26,
          surfaceVariant: Colors.grey,
          outlineVariant: Colors.grey,
          scrim: Colors.black26,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(), // Wrap with auth listener
      debugShowCheckedModeBanner: false,
    );
  }
}

// Auth wrapper for persistence - routes based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listens for login/logout across app
      builder: (context, snapshot) {
        // Debug: Log state
        print('Auth stream state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}'); // Remove after fix
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ); // Loading during auth check
        }
        if (snapshot.hasError) {
          print('Auth stream error: ${snapshot.error}'); // Log errors
          // Fallback to home on error
          return const HomeScreen();
        }
        if (snapshot.hasData) {
          // Logged in: Show HomeScreen
          return const HomeScreen();
        }
        // Not logged in: Show LoginScreen
        return const LoginScreen();
      },
    );
  }
}