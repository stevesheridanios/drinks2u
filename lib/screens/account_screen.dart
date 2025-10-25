import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For JSON
import 'login_screen.dart'; // For navigation

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _userEmail;
  Map<String, dynamic>? _userData;
  List<String> _orderHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
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

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      final orderHistory = prefs.getStringList('order_history') ?? [];
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && mounted) {
        // Sync latest from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final freshData = userDoc.data() as Map<String, dynamic>;
          
          // Convert Timestamps before encoding to prevent JSON error
          final convertedData = _convertTimestamps(freshData);
          print('Timestamp conversion complete - keys: ${convertedData.keys.toList()}'); // Debug
          
          await prefs.setString('user_data', json.encode(convertedData)); // Update prefs safely
          if (mounted) {
            setState(() {
              _userData = convertedData;
              _userEmail = convertedData['email'];
              _orderHistory = orderHistory;
              _isLoading = false;
            });
          }
        } else {
          // Fallback to prefs
          if (mounted) {
            setState(() {
              _userData = userDataStr != null ? json.decode(userDataStr) as Map<String, dynamic> : null;
              _userEmail = _userData?['email'];
              _orderHistory = orderHistory;
              _isLoading = false;
            });
          }
        }
      } else {
        // No auth user—redirect to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login'); // Or direct to LoginScreen
        }
      }
    } catch (e) {
      print('Error loading user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
        setState(() => _isLoading = false);
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          backgroundColor: const Color(0xFF32CD32),
        ),
        body: const Center(
          child: Text('No profile data. Please log in again.'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _logout,
          backgroundColor: Colors.red,
          child: const Icon(Icons.logout),
        ),
      );
    }
    final isBusiness = _userData!['account_type'] == 'business';
    final fullAddress = '${_userData!['streetAddress'] ?? ''}, ${_userData!['location'] ?? ''}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: const Color(0xFF32CD32),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUser,
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

  @override
  void dispose() {
    super.dispose();
  }
}