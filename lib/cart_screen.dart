import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/login_screen.dart';
import '../cart_manager.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  double subtotal = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh on navigation/focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCart();
    });
  }

  Future<void> _loadCart() async {
    print('CartScreen: Starting load...'); // Debug
    try {
      final items = await CartManager.getCartItems();
      final total = await CartManager.getSubtotal();
      if (mounted) {
        setState(() {
          cartItems = items;
          subtotal = total;
          isLoading = false;
          print('CartScreen: Loaded ${items.length} items, subtotal \$${total.toStringAsFixed(2)}'); // Debug
        });
      }
    } catch (e) {
      print('CartScreen load error: $e'); // Debug
      if (mounted) {
        setState(() {
          isLoading = false;
          cartItems = [];
          subtotal = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  Future<void> _decrementItem(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartKey = 'cart_items'; // Hardcode to match CartManager
    List<String> cartJson = prefs.getStringList(cartKey) ?? [];
    bool updated = false;
    for (int i = 0; i < cartJson.length; i++) {
      final item = json.decode(cartJson[i]);
      if (item['id'] == productId) {
        if (item['quantity'] > 1) {
          item['quantity']--;
          cartJson[i] = json.encode(item);
          updated = true;
        } else {
          cartJson.removeAt(i);
          updated = true;
        }
        break;
      }
    }
    if (updated) {
      await prefs.setStringList(cartKey, cartJson);
      await _loadCart(); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated in cart')),
      );
    }
  }

  Future<void> _checkout() async {
    // Check login status
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to place an order.'),
          action: SnackBarAction(
            label: 'Login',
            onPressed: () {
              Navigator.pop(context); // Close cart if open
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Add items first.')),
      );
      return;
    }

    // Fetch user profile from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile not found. Please update your account.')),
      );
      return;
    }
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String customerType = userData['type'] ?? 'personal';  // 'personal' or 'business' (add to account creation if missing)

    // Build customer details HTML table
    String customerDetails = '''
    <h3>Customer Details</h3>
    <table border="1" style="border-collapse: collapse; width: 100%;">
      <tr><th>Customer Type</th><td>${customerType.toUpperCase()}</td></tr>
      <tr><th>Name</th><td>${userData['name'] ?? 'N/A'}</td></tr>
      <tr><th>Email</th><td>${userData['email'] ?? 'N/A'}</td></tr>
      <tr><th>Phone</th><td>${userData['phone'] ?? 'N/A'}</td></tr>
      <tr><th>Address</th><td>${userData['address'] ?? 'N/A'}</td></tr>
    ''';
    if (customerType == 'business') {
      customerDetails += '''
      <tr><th>ABN</th><td>${userData['abn'] ?? 'N/A'}</td></tr>
      <tr><th>Operating Hours</th><td>${userData['hours'] ?? 'N/A'}</td></tr>
      <tr><th>Contact Person</th><td>${userData['contactPerson'] ?? 'N/A'}</td></tr>
      <tr><th>Contact Number</th><td>${userData['contactNumber'] ?? 'N/A'}</td></tr>
      ''';
    }
    customerDetails += '</table>';

    // Order items table
    String orderItems = '<h3>Order Items</h3><table border="1" style="border-collapse: collapse; width: 100%;">';
    orderItems += '<tr><th>Item</th><th>Qty</th><th>Price</th><th>Total</th></tr>';
    for (var item in cartItems) {
      double lineTotal = item['price'] * item['quantity'];
      orderItems += '<tr><td>${item['name']}</td><td>${item['quantity']}</td><td>\$${item['price'].toStringAsFixed(2)}</td><td>\$${lineTotal.toStringAsFixed(2)}</td></tr>';
    }
    orderItems += '<tr><td colspan="3"><strong>Subtotal</strong></td><td>\$${subtotal.toStringAsFixed(2)}</td></tr></table>';

    // Full email body
    String emailBody = '''
    <html>
    <body>
      <h2>New Order from Danfels App</h2>
      $customerDetails
      $orderItems
      <p><strong>Timestamp:</strong> ${DateTime.now().toString()}</p>
      <p><strong>User ID:</strong> ${user.uid}</p>
    </body>
    </html>
    ''';

    // Send email with mailer (your existing SMTP)
    final smtpServer = gmail('steve.sheridan.ios@gmail.com', 'demromgqmodowbjt');
    final message = Message()
      ..from = const Address('steve.sheridan.ios@gmail.com')
      ..recipients = [const Address('steve.sheridan.ios@gmail.com')]
      ..subject = 'New Danfels Order - Total \$${subtotal.toStringAsFixed(2)}'
      ..html = emailBody;

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent! Report: ${sendReport.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order sent via email! Check your inbox.')),
      );
      // Log order to history (local)
      final prefs = await SharedPreferences.getInstance();
      List<String>? orderHistory = prefs.getStringList('order_history');
      orderHistory ??= [];
      final orderLog = 'Order: ${DateTime.now().toString()} - Subtotal: \$${subtotal.toStringAsFixed(2)} - Items: ${cartItems.map((i) => '${i['name']} x${i['quantity']}').join(', ')}';
      orderHistory.add(orderLog);
      await prefs.setStringList('order_history', orderHistory);
      // Save order to Firestore under user UID
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'customerDetails': userData,  // Add full profile for reference
        'items': cartItems,
        'total': subtotal,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Checkout failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e - Check console.')),
      );
    }
    await CartManager.clearCart(); // Clear via manager
    await _loadCart(); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: const Color(0xFF32CD32), // Lime green
      ),
      body: SafeArea( // Wraps for safe zones (nav bar, notch)
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : cartItems.isEmpty
                ? const Center(child: Text('Cart is empty'))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final lineTotal = item['price'] * item['quantity'];
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text('${item['name']} x${item['quantity']}'),
                                subtitle: Text('\$${item['price'].toStringAsFixed(2)} each - Line Total: \$${lineTotal.toStringAsFixed(2)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _decrementItem(item['id']),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0).copyWith(bottom: 32.0), // Extra bottom space for nav bar
                        child: Column(
                          children: [
                            Text('Subtotal: \$${subtotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _checkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF32CD32),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Checkout & Send Order'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadCart, // Manual refresh
        backgroundColor: const Color(0xFF32CD32),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}