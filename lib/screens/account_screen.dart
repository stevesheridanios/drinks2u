import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For JSON
import 'dart:async'; // For timeout
import 'login_screen.dart'; // For navigation

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _userData;
  List<String> _orderHistory = [];
  bool _isProfileLoading = true; // Start true to show spinner
  StreamSubscription<User?>? _authSubscription; // For manual listen

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges(); // Proactive listener
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Proactive listener to catch user emission immediately
  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print('=== DEBUG: Auth listener emitted user: ${user?.uid ?? "null"} ==='); // Debug
      if (user != null && _userData == null && mounted) {
        _loadProfile(user);
      } else if (user == null && mounted) {
        // Redirect if unauth
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      }
    });
  }

  // Robust recursive Timestamp converter for JSON encoding
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final Map<String, dynamic> converted = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        converted[key] = value.toDate().toIso8601String();
        print('Converted Timestamp for key: $key'); // Debug
      } else if (value is Map<String, dynamic>) {
        converted[key] = _convertTimestamps(value);
      } else if (value is List) {
        converted[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _convertTimestamps(item);
          } else if (item is Timestamp) {
            return item.toDate().toIso8601String();
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    });
    return converted;
  }

  Future<void> _loadProfile(User user) async {
    if (!mounted) return;
    print('=== DEBUG: Starting _loadProfile for UID: ${user.uid} ===');
    print('=== DEBUG: CurrentUser in load: ${FirebaseAuth.instance.currentUser?.uid} ==='); // Debug

    setState(() => _isProfileLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      final orderHistory = prefs.getStringList('order_history') ?? [];

      // Quick fallback if prefs has data (bypass Firestore for speed)
      if (userDataStr != null) {
        try {
          final prefsData = json.decode(userDataStr) as Map<String, dynamic>;
          if (prefsData['email'] != null) {
            print('=== DEBUG: Loaded from prefs fallback ===');
            if (mounted) {
              setState(() {
                _userData = prefsData;
                _orderHistory = orderHistory;
                _isProfileLoading = false;
              });
            }
            return; // Success - skip Firestore
          }
        } catch (decodeErr) {
          print('=== DEBUG: Prefs decode failed: $decodeErr ===');
        }
      }

      // Firestore fetch with longer timeout (10s for Android)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            print('=== DEBUG: Firestore timeout - using prefs ===');
            throw TimeoutException('Firestore timeout', const Duration(seconds: 10));
          });

      print('=== DEBUG: Firestore fetch complete ===');

      if (userDoc.exists) {
        final freshData = userDoc.data() as Map<String, dynamic>;
        final convertedData = _convertTimestamps(freshData);
        print('=== DEBUG: Timestamp conversion complete - keys: ${convertedData.keys.toList()} ===');
        
        await prefs.setString('user_data', json.encode(convertedData));
        if (mounted) {
          setState(() {
            _userData = convertedData;
            _orderHistory = orderHistory;
            _isProfileLoading = false;
          });
        }
      } else {
        // Ultimate fallback
        print('=== DEBUG: No Firestore doc - empty profile ===');
        if (mounted) {
          setState(() {
            _userData = null;
            _orderHistory = orderHistory;
            _isProfileLoading = false;
          });
        }
      }
    } catch (e) {
      print('=== DEBUG: Error loading profile: $e ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile load failed: $e - Using cached data')),
        );
        // Force prefs fallback
        final prefs = await SharedPreferences.getInstance();
        final userDataStr = prefs.getString('user_data');
        final orderHistory = prefs.getStringList('order_history') ?? [];
        if (userDataStr != null) {
          try {
            final fallbackData = json.decode(userDataStr) as Map<String, dynamic>;
            setState(() {
              _userData = fallbackData;
              _orderHistory = orderHistory;
              _isProfileLoading = false;
            });
          } catch (_) {
            setState(() => _isProfileLoading = false);
          }
        } else {
          setState(() => _isProfileLoading = false);
        }
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('is_logged_in');
      await prefs.remove('order_history');
      await prefs.setString('pricingMode', 'regional'); // Reset pricing
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('=== DEBUG: Stream snapshot: ${snapshot.connectionState}, User: ${snapshot.data?.uid ?? "null"} ==='); // Debug

        if (snapshot.connectionState == ConnectionState.waiting || _isProfileLoading) {
          print('=== DEBUG: Showing spinner (state: ${snapshot.connectionState}, loading: $_isProfileLoading) ===');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          print('=== DEBUG: No authenticated user - redirecting to login ===');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user exists but no data yet, trigger load (safety net)
        if (_userData == null) {
          print('=== DEBUG: User exists but no data - triggering load ===');
          _loadProfile(user);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Loaded state
        final isBusiness = _userData!['account_type'] == 'business';
        final fullAddress = '${_userData!['streetAddress'] ?? ''}, ${_userData!['location'] ?? ''}';
        return Scaffold(
          appBar: AppBar(
            title: const Text('Account'),
            backgroundColor: const Color(0xFF32CD32),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadProfile(user),
                tooltip: 'Refresh Profile',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${_userData!['email']}'),
                          Text('Account Type: ${isBusiness ? 'Business' : 'Personal'}'),
                          Text('Name: ${_userData!['name']}'),
                          Text('Phone: ${_userData!['phone']}'),
                          Text('Address: $fullAddress'),
                          if (isBusiness) ...[
                            const SizedBox(height: 8),
                            Text('ABN: ${_userData!['abn']}'),
                            Text('Operating Hours: ${_userData!['operating_hours']}'),
                            Text('Contact Name: ${_userData!['contact_name']}'),
                            Text('Contact Phone: ${_userData!['contact_phone']}'),
                          ],
                          // Display converted timestamp if present
                          if (_userData!['created_at'] != null) ...[
                            const SizedBox(height: 8),
                            Text('Joined: ${_userData!['created_at']}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Order History',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (_orderHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No orders yet. Start shopping!')),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orderHistory.length,
                      itemBuilder: (context, index) {
                        final order = _orderHistory[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('Order #${index + 1}'),
                            subtitle: Text(order.length > 50 ? '${order.substring(0, 50)}...' : order),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeOrder(index),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeOrder(int index) async {
    setState(() {
      _orderHistory.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('order_history', _orderHistory);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order removed from history')),
      );
    }
  }
}