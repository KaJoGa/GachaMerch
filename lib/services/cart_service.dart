import 'package:flutter/foundation.dart';
import 'transaction_service.dart';

class CartService {
  // Setiap item berformat: { 'product': Map<String,dynamic>, 'quantity': int }
  static final ValueNotifier<List<Map<String, dynamic>>> cartItems = ValueNotifier([]);

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
  }

  static void removeFromCart(int index) {
    final currentCart = List<Map<String, dynamic>>.from(cartItems.value);
    currentCart.removeAt(index);
    cartItems.value = currentCart;
  }
  
  static void updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;
    final currentCart = List<Map<String, dynamic>>.from(cartItems.value);
    currentCart[index]['quantity'] = newQuantity;
    cartItems.value = currentCart;
  }
  
  static void clearCart() {
    cartItems.value = [];
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
      clearCart();
      return (ok: true, error: null);
    } catch (e) {
      return (ok: false, error: 'Checkout failed: $e');
    }
  }
}
