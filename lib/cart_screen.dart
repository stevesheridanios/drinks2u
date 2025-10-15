import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:convert';
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
    print('CartScreen: Starting load...');  // Debug
    try {
      final items = await CartManager.getCartItems();
      final total = await CartManager.getSubtotal();
      if (mounted) {
        setState(() {
          cartItems = items;
          subtotal = total;
          isLoading = false;
          print('CartScreen: Loaded ${items.length} items, subtotal \$${total.toStringAsFixed(2)}');  // Debug
        });
      }
    } catch (e) {
      print('CartScreen load error: $e');  // Debug
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
    final cartKey = 'cart_items';  // Hardcode to match CartManager
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
      await _loadCart();  // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated in cart')),
      );
    }
  }

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
      ..from = Address('steve.sheridan.ios@gmail.com')  // Sender (match SMTP)
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

    await CartManager.clearCart();  // Clear via manager
    await _loadCart();  // Refresh UI
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Cart'),
      backgroundColor: const Color(0xFF32CD32),  // Lime green
    ),
    body: SafeArea(  // Wraps for safe zones (nav bar, notch)
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
                      padding: const EdgeInsets.all(16.0).copyWith(bottom: 32.0),  // Extra bottom space for nav bar
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
      onPressed: _loadCart,  // Manual refresh
      backgroundColor: const Color(0xFF32CD32),
      child: const Icon(Icons.refresh),
    ),
  );
}
}