import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';  // For Ticker for smooth auto-slide
import 'dart:async';  // For Timer
import 'package:shared_preferences/shared_preferences.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'screens/login_screen.dart';
import 'screens/account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadAuth();  // Load auth status
    // Start auto-slide timer (3 seconds per image)
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentIndex < 2) {  // 3 images: 0, 1, 2
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Slideshow images (your PNGs)
    final List<String> slideshowImages = [
      'assets/images/slide1.png',  // Coconut Water
      'assets/images/slide2.png',  // Aloe Vera
      'assets/images/slide3.png',  // Iced Tea
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danfels'),
        backgroundColor: const Color(0xFF32CD32),  // Lime green
        foregroundColor: Colors.black,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF32CD32),  // Lime green
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black),
              title: const Text('Home', style: TextStyle(color: Colors.black)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Colors.black),
              title: const Text('Products', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.black),
              title: const Text('Cart', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
            if (_isLoggedIn)
              ListTile(
                leading: const Icon(Icons.account_circle, color: Colors.black),
                title: const Text('Account', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountScreen()),
                  );
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login, color: Colors.black),
                title: const Text('Login', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Logo at top (your uploaded logo)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 100,
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Slideshow of 3 images using PageView with auto-slide
          SizedBox(
            height: 551.25,  // Increased by 5% from 525
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: slideshowImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          slideshowImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                    Text('Image Coming Soon!'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                // Navigation dots below slideshow
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slideshowImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? const Color(0xFF32CD32)  // Lime green for current
                              : Theme.of(context).primaryColor.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}