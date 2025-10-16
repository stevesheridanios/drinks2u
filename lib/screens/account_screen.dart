import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _userEmail;
  Map<String, dynamic>? _userData;
  List<String> _orderHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    final orderHistory = prefs.getStringList('order_history') ?? [];
    if (mounted) {
      setState(() {
        _userData = userDataStr != null ? json.decode(userDataStr) as Map<String, dynamic> : null;
        _userEmail = _userData?['email'];
        _orderHistory = orderHistory;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('is_logged_in');
    await prefs.remove('order_history');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');  // Or pop to Home
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isBusiness = _userData!['account_type'] == 'business';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: const Color(0xFF32CD32),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile:', style: Theme.of(context).textTheme.headlineSmall),
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
                    Text('Address: ${_userData!['address']}'),
                    if (isBusiness) ...[
                      Text('ABN: ${_userData!['abn']}'),
                      Text('Operating Hours: ${_userData!['operating_hours']}'),
                      Text('Contact Name: ${_userData!['contact_name']}'),
                      Text('Contact Phone: ${_userData!['contact_phone']}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Order History:', style: Theme.of(context).textTheme.headlineSmall),
            _orderHistory.isEmpty
                ? const Center(child: Text('No orders yet.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _orderHistory.length,
                    itemBuilder: (context, index) {
                      final order = _orderHistory[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text('Order #${index + 1}'),
                          subtitle: Text(order.substring(0, 50) + '...'),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}