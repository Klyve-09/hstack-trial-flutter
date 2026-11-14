import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';

class ItemsRepository {
  static const storageKey = 'items';

  Future<List<Item>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(storageKey);
    if (stored == null) return [];

    final decoded = jsonDecode(stored);
    if (decoded is! List) {
      throw const FormatException('Invalid notebook data');
    }
    return decoded.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid item data');
      }
      return Item.fromJson(entry);
    }).toList();
  }

  Future<void> add(Item item) async {
    final items = await load();
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      storageKey,
      jsonEncode([item, ...items].map((item) => item.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save item');
  }
}
