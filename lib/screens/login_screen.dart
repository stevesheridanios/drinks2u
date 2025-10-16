import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';  // For JSON and simple hash (demo only)
import 'account_screen.dart';  // Nav to Account (same folder)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isCreatingAccount = false;
  bool _isBusinessAccount = false;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();  // Personal/Business name
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _abnController = TextEditingController();  // Business only
  final _operatingHoursController = TextEditingController();  // Business only
  final _contactNameController = TextEditingController();  // Business only
  final _contactPhoneController = TextEditingController();  // Business only

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showSnackBar('Please enter email and password');
        return;
      }

      if (_isCreatingAccount) {
        print('Creating account for $email');  // Debug
        // Registration validation
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        final address = _addressController.text.trim();
        if (name.isEmpty || phone.isEmpty || address.isEmpty) {
          _showSnackBar('Please fill all required fields: Name, Phone, Address');
          return;
        }
        if (_isBusinessAccount) {
          final abn = _abnController.text.trim();
          final hours = _operatingHoursController.text.trim();
          final contactName = _contactNameController.text.trim();
          final contactPhone = _contactPhoneController.text.trim();
          if (abn.isEmpty || hours.isEmpty || contactName.isEmpty || contactPhone.isEmpty) {
            _showSnackBar('Please fill all business fields: ABN, Hours, Contact Name, Contact Phone');
            return;
          }
        }

        // Create user data JSON
        Map<String, dynamic> userData = {
          'email': email,
          'password_hash': base64Encode(utf8.encode(password)),  // Demo hash
          'account_type': _isBusinessAccount ? 'business' : 'personal',
          'name': name,
          'phone': phone,
          'address': address,
        };
        if (_isBusinessAccount) {
          userData.addAll({
            'business_name': name,  // Name = Business Name
            'abn': _abnController.text.trim(),
            'operating_hours': _operatingHoursController.text.trim(),
            'contact_name': _contactNameController.text.trim(),
            'contact_phone': _contactPhoneController.text.trim(),
          });
        }

        await prefs.setString('user_data', json.encode(userData));
        _showSnackBar('Account created successfully for $email!');
      } else {
        print('Logging in for $email');  // Debug
        // Login: Check stored data
        final storedData = prefs.getString('user_data');
        if (storedData == null) {
          _showSnackBar('No account found. Create one first.');
          return;
        }
        final userData = json.decode(storedData) as Map<String, dynamic>;
        if (userData['email'] != email || userData['password_hash'] != base64Encode(utf8.encode(password))) {
          _showSnackBar('Invalid email or password');
          return;
        }
        _showSnackBar('Logged in successfully as $email!');
      }

      // Success: Set logged in
      await prefs.setBool('is_logged_in', true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccountScreen()),
        );
      }
    } catch (e) {
      print('Login error: $e');  // Debug
      if (mounted) _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _toggleCreateAccount(bool? value) {
    setState(() {
      _isCreatingAccount = value ?? false;
      if (!_isCreatingAccount) _isBusinessAccount = false;  // Reset business when switching to login
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreatingAccount ? 'Create Account' : 'Login'),
        backgroundColor: const Color(0xFF32CD32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Color(0xFF32CD32)),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _isCreatingAccount ? null : _handleSubmit,  // Disable if creating or loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32CD32),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            // Toggle for Create Account
            Row(
              children: [
                Checkbox(
                  value: _isCreatingAccount,
                  onChanged: _toggleCreateAccount,
                ),
                const Expanded(child: Text('Create New Account')),
              ],
            ),
            if (_isCreatingAccount) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _isBusinessAccount ? 'Business Name' : 'Customer Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Business toggle (only if creating account)
              Row(
                children: [
                  const Text('Business Account? '),
                  Switch(
                    value: _isBusinessAccount,
                    onChanged: (value) => setState(() => _isBusinessAccount = value),
                  ),
                ],
              ),
              if (_isBusinessAccount) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _abnController,
                  decoration: const InputDecoration(
                    labelText: 'ABN Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _operatingHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Operating Hours (e.g., Mon-Fri 9-5)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contactNameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF32CD32),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Create Account', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _abnController.dispose();
    _operatingHoursController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }
}