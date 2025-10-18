import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import the new HomeScreen file
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: const HomeScreen(),
    );
  }
}