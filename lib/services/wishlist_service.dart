import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WishlistService {
  static const String _key = "wishlist_items";

  static Future<List<Map<String, dynamic>>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_key) ?? [];

    return rawItems
        .map((raw) => jsonDecode(raw))
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<bool> add(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await list();
    final id = product["id"]?.toString();

    if (id != null && items.any((item) => item["id"]?.toString() == id)) {
      return false;
    }

    items.add({
      "id": product["id"],
      "name": product["name"],
      "image": product["image"],
      "price": product["price"],
      "stock": product["stock"],
      "item_type": product["item_type"],
    });

    await prefs.setStringList(
      _key,
      items.map((item) => jsonEncode(item)).toList(),
    );
    return true;
  }

  static Future<bool> remove(dynamic productId) async {
    final prefs = await SharedPreferences.getInstance();
    final id = productId?.toString();
    if (id == null) return false;

    final items = await list();
    final filtered = items
        .where((item) => item["id"]?.toString() != id)
        .toList();

    if (filtered.length == items.length) return false;

    await prefs.setStringList(
      _key,
      filtered.map((item) => jsonEncode(item)).toList(),
    );
    return true;
  }
}
