import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode and TargetPlatform
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For JSON
import 'dart:io'; // For Platform
import 'account_screen.dart'; // Same folder

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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _locationController = TextEditingController();
  final _abnController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    User? user; // Scoped for cleanup
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Pre-validation (applies to both login and create)
      if (email.isEmpty || password.isEmpty) {
        _showSnackBar('Please enter email and password');
        return;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _showSnackBar('Please enter a valid email address');
        return;
      }
      if (password.length < 6) {
        _showSnackBar('Password must be at least 6 characters long');
        return;
      }
      // Enhanced client-side password strength check (avoids Firebase 'internal-error' on iOS)
      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
        _showSnackBar('Password must include uppercase, lowercase, and a number (e.g., Test123)');
        return;
      }
      print('Password validated client-side: OK'); // Debug log

      if (_isCreatingAccount) {
        // Declare fields upfront for scope
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        final street = _streetAddressController.text.trim();
        final location = _locationController.text.trim();
        String? abn, hours, contactName, contactPhone;
        if (name.isEmpty || phone.isEmpty || street.isEmpty || location.isEmpty) {
          _showSnackBar('Please fill all required fields: Name, Phone, Street Address, Location');
          return;
        }
        final suburb = _extractSuburbFromLocation(location);
        if (suburb == null || suburb.isEmpty) {
          _showSnackBar('Please enter a valid suburb in Location (e.g., Bexley North NSW 2207)');
          return;
        }
        if (_isBusinessAccount) {
          abn = _abnController.text.trim();
          hours = _operatingHoursController.text.trim();
          contactName = _contactNameController.text.trim();
          contactPhone = _contactPhoneController.text.trim();
          if (abn.isEmpty || hours.isEmpty || contactName.isEmpty || contactPhone.isEmpty) {
            _showSnackBar('Please fill all business fields');
            return;
          }
        }

        // Temporary bypass for iOS testing (remove in production)
        if (kDebugMode && Platform.isIOS) {
          await FirebaseAuth.instance.setSettings(
            appVerificationDisabledForTesting: true,
          );
          print('Debug: Disabled app verification for iOS testing');
        }

        // Create user
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = credential.user;
        if (user == null) {
          _showSnackBar('Failed to create account');
          return;
        }

        // Prepare and save user data to Firestore
        Map<String, dynamic> userData = {
          'email': email,
          'account_type': _isBusinessAccount ? 'business' : 'personal',
          'name': name,
          'phone': phone,
          'streetAddress': street,
          'location': location,
          'suburb': suburb,
          'created_at': FieldValue.serverTimestamp(),
        };
        if (_isBusinessAccount && abn != null) {
          userData.addAll({
            'business_name': name,
            'abn': abn,
            'operating_hours': hours,
            'contact_name': contactName,
            'contact_phone': contactPhone,
          });
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData);
        _showSnackBar('Account created successfully!');
      } else {
        // Login
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = credential.user;
        _showSnackBar('Logged in successfully!');
      }

      // Post-auth: Sync profile and pricing
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            // Clone and convert all Timestamps for JSON encoding (robust recursive)
            Map<String, dynamic> userData = _convertTimestamps(Map<String, dynamic>.from(userDoc.data()!));
            print('Timestamp conversion complete - userData keys: ${userData.keys.toList()}'); // Debug
            await prefs.setString('user_data', json.encode(userData));

            // Set pricing mode: Prefer saved suburb, fallback to extraction
            String? suburb = userData['suburb']?.toString();
            if (suburb == null || suburb.isEmpty) {
              final locationOrAddress = userData['location'] ?? userData['address'] ?? '';
              suburb = _extractSuburbFromLocation(locationOrAddress);
            }
            if (suburb != null && suburb.isNotEmpty) {
              final isMetro = await _checkMetroSuburb(suburb);
              final pricingMode = isMetro ? 'metro' : 'regional';
              await prefs.setString('pricingMode', pricingMode);
              print('Set pricing mode: $pricingMode for suburb: $suburb');
            } else {
              print('No valid suburb found - defaulting to regional pricing');
              await prefs.setString('pricingMode', 'regional');
            }
          }
        } catch (firestoreError) {
          print('Firestore sync error: $firestoreError');
          _showSnackBar('Logged in, but profile load failed—retry later');
          // Default to regional on error
          await prefs.setString('pricingMode', 'regional');
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AccountScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error: code=${e.code}, message=${e.message}');
      if (e.stackTrace != null) print('Stack trace: ${e.stackTrace}');
      // iOS-specific logging for underlying NSError (common cause of internal-error)
      if (Platform.isIOS) {
        print('iOS Auth error details: Check Xcode console for FIRAuthErrorDomain or NSError userInfo');
      }
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'weak-password':
          message = 'Password is too weak (must be 6+ chars, mix of letters/numbers).';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password sign-in not enabled. Check Firebase Console.';
          break;
        case 'internal-error':
          message = 'Internal server error. Check Google Cloud API key restrictions or Xcode logs for details.';
          break;
        default:
          message = 'Auth failed: ${e.message ?? 'Unknown error (code: ${e.code})'}';
      }
      _showSnackBar(message);
      // Cleanup on creation failure
      if (_isCreatingAccount && user != null) {
        try {
          await user.delete();
          print('Cleaned up failed user: ${user.uid}');
        } catch (deleteError) {
          print('Cleanup failed: $deleteError');
        }
      }
    } catch (e) {
      print('General error: $e');
      _showSnackBar('Connection issue: $e. Verify internet and retry.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  // Improved suburb extraction from location field (e.g., "Bexley North NSW 2207")
  String? _extractSuburbFromLocation(String location) {
    if (location.isEmpty) return null;
    String locationText = location.trim().toLowerCase();
    
    // List of common Australian states/territories (lowercase)
    List<String> states = ['nsw', 'vic', 'qld', 'sa', 'wa', 'tas', 'act', 'nt'];
    
    // Split by space, take words until postcode (4-5 digits) or state
    List<String> parts = locationText.split(' ');
    Iterable<String> suburbParts = parts.takeWhile((part) => 
      !RegExp(r'^\d{4,5}$').hasMatch(part) && !states.contains(part)
    );
    String suburb = suburbParts.join(' ').trim();
    
    // Fallback: If no clear suburb, strip trailing numbers/spaces
    if (suburb.isEmpty) {
      suburb = locationText.replaceAll(RegExp(r'[0-9\s]+$'), '').trim();
    }
    
    // Clean up common artifacts (e.g., remove standalone "st")
    suburb = suburb.replaceAll(RegExp(r'\bst\b'), '').trim();
    
    // Validate: Letters and spaces only, min length > 2
    if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(suburb) && suburb.length > 2) {
      print('Extracted suburb: "$suburb" from location: "$locationText"'); // Debug
      return suburb;
    }
    return null;
  }

  Future<bool> _checkMetroSuburb(String suburb) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('metro_suburbs').get();
      if (doc.exists) {
        final suburbs = doc.data()?['suburbs'] ?? <dynamic>[];
        // Fuzzy match: Check if suburb or words match any in list (handles variations)
        final suburbWords = suburb.split(' ');
        return suburbs.any((s) {
          final sStr = s.toString().toLowerCase();
          return sStr == suburb.toLowerCase() || 
                 sStr.contains(suburb.toLowerCase()) || 
                 suburbWords.any((word) => sStr.contains(word.toLowerCase()));
        });
      }
    } catch (e) {
      print('Suburb check error: $e'); // Graceful: Defaults to regional
    }
    return false; // Default to regional on error
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
    }
  }

  void _toggleCreateAccount(bool? value) {
    setState(() {
      _isCreatingAccount = value ?? false;
      if (!_isCreatingAccount) _isBusinessAccount = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreatingAccount ? 'Create Account' : 'Login'),
        backgroundColor: const Color(0xFF32CD32),
      ),
      body: SafeArea( // Added to prevent NaN layout issues on iOS
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100, color: Color(0xFF32CD32)),
              const SizedBox(height: 32),
              RepaintBoundary( // Fixes NaN on input (e.g., typing '@')
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false, // Reduces keyboard calc errors
                  enableSuggestions: false,
                ),
              ),
              const SizedBox(height: 16),
              RepaintBoundary( // Fixes NaN on input
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _isCreatingAccount ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF32CD32),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),
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
                RepaintBoundary(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _isBusinessAccount ? 'Business Name' : 'Customer Name',
                      border: const OutlineInputBorder(),
                    ),
                    autocorrect: false,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    autocorrect: false,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: TextField(
                    controller: _streetAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address (e.g., 40 Shaw St)',
                      border: OutlineInputBorder(),
                    ),
                    autocorrect: false,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Suburb, State Postcode (e.g., Bexley North NSW 2207)',
                      border: OutlineInputBorder(),
                    ),
                    autocorrect: false,
                  ),
                ),
                const SizedBox(height: 16),
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
                  RepaintBoundary(
                    child: TextField(
                      controller: _abnController,
                      decoration: const InputDecoration(
                        labelText: 'ABN Number',
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    child: TextField(
                      controller: _operatingHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Operating Hours (e.g., Mon-Fri 9-5)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      autocorrect: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    child: TextField(
                      controller: _contactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                        border: OutlineInputBorder(),
                      ),
                      autocorrect: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    child: TextField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      autocorrect: false,
                    ),
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Text('Create Account', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ],
          ),
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
    _streetAddressController.dispose();
    _locationController.dispose();
    _abnController.dispose();
    _operatingHoursController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }
}