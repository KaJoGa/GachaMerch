import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'transaction_service.dart';
import 'notification_service.dart';

class CartService {
  // Setiap item berformat: { 'product': Map<String,dynamic>, 'quantity': int }
  static final ValueNotifier<List<Map<String, dynamic>>> cartItems = ValueNotifier([]);

  static Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    if (email == null) return;
    
    final cartStr = prefs.getString("cart_$email");
    if (cartStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartStr);
        cartItems.value = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        cartItems.value = [];
      }
    } else {
      cartItems.value = [];
    }
  }

  static Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    if (email == null) return;
    
    await prefs.setString("cart_$email", jsonEncode(cartItems.value));
  }

  static void addToCart(Map<String, dynamic> product, int quantity) {
    final currentCart = List<Map<String, dynamic>>.from(cartItems.value);
    
    // Cek apakah item sudah ada di keranjang
    final index = currentCart.indexWhere((item) => item['product']['id'] == product['id']);
    
    if (index >= 0) {
      currentCart[index]['quantity'] += quantity;
    } else {
      currentCart.add({
        'product': product,
        'quantity': quantity,
      });
    }
    
    cartItems.value = currentCart;
    saveCart();

    NotificationService.addNotification(
      "Don't forget to checkout!",
      "You added ${product['name']} to your cart.",
    );
  }

  static void removeFromCart(int index) {
    final currentCart = List<Map<String, dynamic>>.from(cartItems.value);
    currentCart.removeAt(index);
    cartItems.value = currentCart;
    saveCart();
  }
  
  static void updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;
    final currentCart = List<Map<String, dynamic>>.from(cartItems.value);
    currentCart[index]['quantity'] = newQuantity;
    cartItems.value = currentCart;
    saveCart();
  }
  
  static void clearCart({bool save = true}) {
    cartItems.value = [];
    if (save) saveCart();
  }

  static Future<({bool ok, String? error})> checkout() async {
    final items = cartItems.value;
    if (items.isEmpty) return (ok: false, error: 'Cart is empty');

    try {
      for (var item in items) {
        final productId = item['product']['id'];
        final quantity = item['quantity'];
        final int parsedId = int.tryParse(productId.toString()) ?? 0;
        final int parsedQty = int.tryParse(quantity.toString()) ?? 0;
        final res = await TransactionService.buy(parsedId, parsedQty);
        if (!res.ok) {
          // Jika gagal, hentikan proses. Barang yang sudah sukses sebelum ini tetap sukses.
          // Ini adalah pendekatan sederhana karena backend tidak mendukung batch insert.
          return (ok: false, error: 'Failed buying ${item['product']['name']}: ${res.error}');
        }
      }
      clearCart(save: true);
      return (ok: true, error: null);
    } catch (e) {
      return (ok: false, error: 'Checkout failed: $e');
    }
  }
}
