import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Settings
import 'package:firebase_auth/firebase_auth.dart'; // For auth state listener
import 'package:package_info_plus/package_info_plus.dart'; // For current app version
import 'package:url_launcher/url_launcher.dart'; // For opening App Store/Play Store
import 'dart:io'; // NEW: For Platform checks (iOS vs Android)
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

// NEW: Function to check for app updates
Future<void> checkForUpdate(BuildContext context) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // TODO: Fetch latest version from your server API (e.g., via http.get('https://your-server.com/version.json'))
    const latestVersion = '1.17.2';  // Hardcoded for now—replace with dynamic fetch

    if (latestVersion != currentVersion) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Available'),
          content: Text('A new version of Danfels ($latestVersion) is available. Update for the latest features!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchStore(packageInfo);
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    print('Update check error: $e'); // Log silently
  }
}

// NEW: Launch App Store (iOS) or Play Store (Android)
Future<void> _launchStore(PackageInfo packageInfo) async {
  final Uri url;
  if (Platform.isIOS) {
    url = Uri.parse('https://apps.apple.com/app/id6754541315'); // Your App ID
  } else {
    url = Uri.parse('https://play.google.com/store/apps/details?id=${packageInfo.packageName}');
  }

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
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
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // NEW: Check for updates after init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdate(context);
    });
  }

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
          print('Auth stream error: $snapshot.error'); // Log errors
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