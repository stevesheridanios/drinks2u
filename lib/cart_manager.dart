import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/product.dart';

class CartManager {
  static const String _cartKey = 'cart_items';
  static const String _oldCartKey = 'cart';  // For migration

  static Future<void> addToCart(Product product) async {
    print('Adding ${product.name} (ID: ${product.id}) to cart...');  // Debug start
    final prefs = await SharedPreferences.getInstance();
    List<String> cartJson = await _getOrMigrateCart(prefs);  // Use migrated list
    print('Current cart has ${cartJson.length} items before add');  // Debug pre-add
    Map<String, dynamic> cartItem = {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'quantity': 1,
    };

    bool found = false;
    for (int i = 0; i < cartJson.length; i++) {
      final item = json.decode(cartJson[i]);
      if (item['id'] == product.id) {
        item['quantity'] = (item['quantity'] as int) + 1;
        cartJson[i] = json.encode(item);
        found = true;
        print('Incremented quantity for ${product.name} to ${item['quantity']}');  // Debug update
        break;
      }
    }
    if (!found) {
      cartJson.add(json.encode(cartItem));
      print('Added new: ${product.name} (qty 1)');  // Debug new add
    }

    await prefs.setStringList(_cartKey, cartJson);
    print('Saved cart with ${cartJson.length} items under key: $_cartKey');  // Debug post-save
  }

  static Future<void> addToCartWithQuantity(Product product, int initialQuantity) async {
    print('Adding ${product.name} (ID: ${product.id}) x$initialQuantity to cart...');  // Debug
    final prefs = await SharedPreferences.getInstance();
    List<String> cartJson = await _getOrMigrateCart(prefs);
    print('Current cart has ${cartJson.length} items before add');  // Debug pre-add
    Map<String, dynamic> cartItem = {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'quantity': initialQuantity,
    };

    bool found = false;
    for (int i = 0; i < cartJson.length; i++) {
      final item = json.decode(cartJson[i]);
      if (item['id'] == product.id) {
        item['quantity'] = (item['quantity'] as int) + initialQuantity;
        cartJson[i] = json.encode(item);
        found = true;
        print('Incremented quantity for ${product.name} to ${item['quantity']}');  // Debug update
        break;
      }
    }
    if (!found) {
      cartJson.add(json.encode(cartItem));
      print('Added new: ${product.name} x$initialQuantity');  // Debug new add
    }

    await prefs.setStringList(_cartKey, cartJson);
    print('Saved cart with ${cartJson.length} items under key: $_cartKey');  // Debug post-save
  }

  static Future<void> removeFromCart(int productId) async {
    print('Removing item ID: $productId from cart...');  // Debug
    final prefs = await SharedPreferences.getInstance();
    List<String> cartJson = await _getOrMigrateCart(prefs);  // Use migrated
    print('Cart had ${cartJson.length} items before remove');  // Debug pre-remove
    cartJson.removeWhere((itemJson) {
      final item = json.decode(itemJson);
      return item['id'] == productId;
    });
    await prefs.setStringList(_cartKey, cartJson);
    print('Cart now has ${cartJson.length} items after remove');  // Debug post-remove
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartJson = await _getOrMigrateCart(prefs);  // Ensures migration
    print('Loading cart: Found ${cartJson.length} JSON strings under $_cartKey');  // Debug load
    List<Map<String, dynamic>> items = cartJson.map((jsonStr) => json.decode(jsonStr) as Map<String, dynamic>).toList();
    print('Decoded ${items.length} cart items');  // Debug post-decode
    return items;
  }

  static Future<double> getSubtotal() async {
    print('Calculating subtotal...');  // Debug
    final items = await getCartItems();
    double total = items.fold<double>(
      0.0,
      (double sum, Map<String, dynamic> item) =>
          sum + ((item['price'] as double) * (item['quantity'] as int)),
    );
    print('Subtotal calculated: $total');  // Debug result
    return total;
  }

  static Future<void> clearCart() async {
    print('Clearing cart...');  // Debug
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    print('Cart cleared under $_cartKey');  // Debug post-clear
  }

  // Private: Get cart list, migrate from old key if needed
  static Future<List<String>> _getOrMigrateCart(SharedPreferences prefs) async {
    List<String> cartJson = prefs.getStringList(_cartKey) ?? [];
    if (cartJson.isEmpty) {
      List<String>? oldCart = prefs.getStringList(_oldCartKey);
      if (oldCart != null && oldCart.isNotEmpty) {
        print('Migrating ${oldCart.length} items from old key "$_oldCartKey" to "$_cartKey"');  // Debug migration
        await prefs.setStringList(_cartKey, oldCart);
        await prefs.remove(_oldCartKey);  // Clean up old
        cartJson = oldCart;
      }
    }
    return cartJson;
  }
}