import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../../models/product.dart';
import '../../cart_manager.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isCarton = false; // Toggle unit vs carton

  @override
  void initState() {
    super.initState();
    print('Detail init for ${widget.product.name} (ID: ${widget.product.id}): description = "${widget.product.description}" (length: ${widget.product.description.length})'); // Debug on entry
  }

  Future<void> _addToCart() async {
    final effectiveQuantity = _isCarton ? (_quantity * 6) : _quantity; // e.g., 1 carton = 6 units
    final unitLabel = _isCarton ? ' carton(s)' : ' unit(s)';
    try {
      await CartManager.addToCartWithQuantity(widget.product, effectiveQuantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product.name} x${_quantity}$unitLabel (${effectiveQuantity} total units) added to cart!')),
        );
      }
      print('Added ${widget.product.name}: qty=${_quantity} (carton: $_isCarton) -> effective ${effectiveQuantity} units'); // Debug confirm
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final desc = product.description ?? ''; // Safe handling
    final unitPrice = product.price; // Base unit price
    final cartonPrice = unitPrice * 6; // Hardcoded 6 per carton
    final displayPrice = _isCarton ? cartonPrice : unitPrice;
    final total = displayPrice * _quantity; // Total based on selected qty (not effective for add)
    print('Build for ${product.name}: final desc = "$desc" (length: ${desc.length})'); // Debug on build

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: const Color(0xFF32CD32), // Lime green
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (unchanged)
            Center(
              child: (product.image?.isNotEmpty ?? false)
                  ? (product.image!.startsWith('http')
                      ? Image.network(
                          product.image!,
                          height: 250,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) =>
                              loadingProgress == null ? child : const CircularProgressIndicator(),
                          errorBuilder: (context, error, stackTrace) {
                            if (kDebugMode) print('Network image error: $error');
                            return const Icon(Icons.error, size: 250);
                          },
                        )
                      : Image.asset(
                          product.image!,
                          height: 250,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            if (kDebugMode) print('Asset image error: $error');
                            return const Icon(Icons.error, size: 250);
                          },
                        ))
                  : const Icon(Icons.image_not_supported, size: 250),
            ),
            const SizedBox(height: 16),
            // Name (unchanged)
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // Price (updated for clarity on unit/carton)
            Text(
              '\$${unitPrice.toStringAsFixed(2)} per unit${_isCarton ? ' | \$${cartonPrice.toStringAsFixed(2)} per carton' : ''}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF32CD32)),
            ),
            const SizedBox(height: 8),
            // Toggle Unit/Carton (unchanged)
            Row(
              children: [
                const Text('Buy by carton (6-pack)? '),
                Switch(
                  value: _isCarton,
                  onChanged: (_) {
                    setState(() {
                      _isCarton = ! _isCarton;
                      _quantity = _isCarton ? 1 : _quantity; // Reset qty to 1 on toggle if desired
                    });
                  },
                ),
              ],
            ),
            if (_isCarton) Text('Price for carton: \$${cartonPrice.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            // Quantity Selector (updated label for context)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Quantity: ', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
                if (_isCarton) Text('(x6 units each)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            // Total (updated to reflect display price * qty, but note effective for cart is different)
            Text(
              'Subtotal: \$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green),
            ),
            const SizedBox(height: 16),
            // Description (unchanged)
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              desc.isEmpty ? 'No description available.' : desc,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: null, // Updated: Unlimited lines for full text
              overflow: TextOverflow.visible, // Updated: No truncation
              softWrap: true, // Ensures proper line wrapping
            ),
            const SizedBox(height: 16), // Extra space before button
            // Add to Cart Button (unchanged)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32CD32),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}