import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:convert';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];  // Starts empty

  @override
  void initState() {
    super.initState();
    _loadCart();  // Load from storage on start
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = prefs.getStringList('cart') ?? [];
    setState(() {
      cartItems = cartList.map((item) => Map<String, dynamic>.from(jsonDecode(item))).toList();
    });
  }

  double get subtotal => cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));

  Future<void> _checkout() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Add items first.')),
      );
      return;
    }

    // Format order as plain text for email body
    String emailBody = 'Danfels Order Summary\n\n';
    emailBody += 'Items:\n';
    for (var item in cartItems) {
      emailBody += '- ${item['name']} \$${item['price']} x ${item['quantity']} = \$${ (item['price'] * item['quantity']).toStringAsFixed(2) }\n';
    }
    emailBody += '\nTotal: \$${subtotal.toStringAsFixed(2)}\n';
    emailBody += 'Timestamp: ${DateTime.now().toString()}';

    // Send real email (replace placeholders with your Gmail sender and app password)
    final smtpServer = gmail('steve.sheridan.ios@gmail.com', 'demromgqmodowbjt');  // e.g., 'steve.sheridan.ios@gmail.com', 'abcd efgh ijkl mnop'
    final message = Message()
      ..from = Address('your-gmail@gmail.com')  // Sender
      ..recipients = [Address('steve.sheridan.ios@gmail.com')]  // Test recipient
      ..subject = 'New Danfels Order - Total \$${subtotal.toStringAsFixed(2)}'
      ..text = emailBody;  // Order details in body

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent! Report: ${sendReport.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order sent via email! Check your inbox.')),
      );
    } catch (e) {
      print('Email failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email send failed: $e - Check console.')),
      );
    }

    setState(() {
      cartItems.clear();  // Empty cart
    });
    await _clearCartStorage();  // Clear local storage
  }

  Future<void> _clearCartStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(item['name']),
                          subtitle: Text('\$${item['price']} x ${item['quantity']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (item['quantity'] > 1) {
                                  item['quantity']--;
                                } else {
                                  cartItems.removeAt(index);
                                }
                              });
                              _saveCart();  // Update storage
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
    );
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartList = cartItems.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cart', cartList);
  }
}